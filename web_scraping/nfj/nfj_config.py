import json
import re
import time
from typing import Dict, Any

from bs4 import BeautifulSoup
from urllib.parse import urljoin

from job_scraper.config import SiteConfig, PaginationConfig, JobFieldSelectors
from job_scraper.base_scraper import ConfigurableJobScraper
from job_scraper.models import Salary
from job_scraper.text_utils import normalize_ws

BASE = "https://nofluffjobs.com"
CARD_SELECTOR = "a.posting-list-item"
LOAD_MORE_NAME_REGEX = re.compile(r"Pokaż kolejne oferty|Load more", re.I)

H = {
    "must": ["Obowiązkowe", "Must have", "Requirements"],
    "nice": ["Mile widziane", "Nice to have"],
    "resp": ["Zakres obowiązków", "Responsibilities"],
    "off": ["Opis oferty", "Offer description", "About the role"],
}


def nfj_site_config(level: str) -> SiteConfig:
    level = level.lower()
    seniority = {
        "trainee": "seniority%3Dtrainee",
        "junior": "seniority%3Djunior",
        "mid": "seniority%3Dmid",
        "senior": "seniority%3Dsenior",
    }[level]

    base_url = f"https://nofluffjobs.com/pl/?criteria={seniority}"

    return SiteConfig(
        name=f"nofluffjobs_{level}",
        base_url=base_url,
        listing_container_selector=CARD_SELECTOR,
        offer_link_selector="&self",  # cały kafelek jest linkiem
        cookie_accept_selector=None,   # obsłużymy customowo
        extra_click_selectors=[],
        geo_fix_script=None,          # obsłużymy customowo
        pagination=PaginationConfig(
            mode="infinite",
            infinite_scroll_pause=0.9,
            infinite_scroll_max_steps=60,
        ),
        fields=JobFieldSelectors(
            title="h1,[data-cy='posting-title-position'],.posting-title__position",
            company=".company-name,[data-cy='company-name']",
            location=".posting-info__location,[data-cy='posting-location']",
            salary=".salary,.posting-salary__value,[data-cy='salary-range']",
            tech_stack="[data-cy='must-have'] li,[data-cy='nice-to-have'] li",
            description="[data-cy='posting-description'],[data-cy='offer-description']",
        ),
    )


# ========= HELPERY Z TWOJEGO DZIAŁAJĄCEGO KODU =========

def accept_cookies(page):
    try:
        page.get_by_role(
            "button",
            name=re.compile(r"Akceptuj wszystkie|Accept all", re.I)
        ).click(timeout=7000)
        return
    except:
        pass

    for sel in [
        "#accept",
        "button.uc-accept-button",
        "button[data-action-type='accept']",
        "button:has-text('Akceptuj')",
        "button:has-text('Accept')",
    ]:
        try:
            btn = page.locator(sel)
            if btn.count() and btn.first.is_visible():
                btn.first.click()
                break
        except:
            pass


def close_signup_popup_if_shown(page):
    time.sleep(6)
    try:
        popup = page.locator("div").filter(has_text="Załóż konto i zgarnij")
        if popup.count() > 0:
            popup.nth(1).click()
            time.sleep(0.3)
    except:
        pass


def dismiss_geo_modal(page):
    time.sleep(0.3)
    try:
        geo = page.locator("text=You're viewing our website").or_(
            page.locator("text=Switch to Czechia site")
        )
        if geo.count() == 0:
            geo = page.locator(
                "[role='dialog'], [class*=modal], [class*=Dialog], [class*=dialog]"
            )

        if geo.count() and geo.first.is_visible():
            try:
                page.get_by_role(
                    "button",
                    name=re.compile(r"close|zamknij", re.I)
                ).click(timeout=1200)
                return True
            except:
                pass
            try:
                close_icon = page.locator("css=use[href='#md-close']")
                if close_icon.count() and close_icon.first.is_visible():
                    page.evaluate(
                        """
                        (el) => {
                          let n = el;
                          while (n && !(n instanceof HTMLElement)) n = n.parentNode;
                          while (n && !(n.tagName==='BUTTON' || n.getAttribute('role')==='button')) n = n.parentElement;
                          (n || el.parentElement)?.click();
                        }
                        """,
                        close_icon.first,
                    )
                    return True
            except:
                pass
            try:
                page.keyboard.press("Escape")
                time.sleep(0.2)
                if not geo.first.is_visible():
                    return True
            except:
                pass
            try:
                page.locator("[class*=overlay]").first.click()
                return True
            except:
                pass
    except:
        pass
    return False


def install_geo_killer(page):
    page.add_init_script(
        """
        try {
          localStorage.setItem('country', 'PL');
          localStorage.setItem('nfj-country', 'PL');
          localStorage.setItem('geoDismissed', '1');
        } catch (e) {}

        try {
          Object.defineProperty(navigator, 'language', { get: () => 'pl-PL' });
          Object.defineProperty(navigator, 'languages', { get: () => ['pl-PL','pl','en'] });
        } catch (e) {}

        try {
          const _geo = navigator.geolocation;
          if (_geo) {
            const pos = { coords: { latitude: 52.2297, longitude: 21.0122, accuracy: 30 } };
            navigator.getCurrentPosition = (succ, err) => succ && succ(pos);
          }
        } catch (e) {}
        """
    )


def collect_listing_links_like_old(page, list_url: str) -> list[str]:
    page.goto(list_url, wait_until="domcontentloaded")
    accept_cookies(page)
    close_signup_popup_if_shown(page)
    dismiss_geo_modal(page)

    page.wait_for_selector(CARD_SELECTOR, timeout=20000)
    prev_count = -1
    links_set = set()

    while True:
        cards = page.locator(CARD_SELECTOR)
        count = cards.count()

        for i in range(count):
            href = cards.nth(i).get_attribute("href") or ""
            if href:
                links_set.add(urljoin(BASE, href))

        clicked = False
        try:
            btn = page.get_by_role("button", name=LOAD_MORE_NAME_REGEX)
            if btn.count() and btn.first.is_visible():
                before = cards.count()
                btn.first.click()
                page.wait_for_function(
                    "(before) => document.querySelectorAll('a.posting-list-item[href]').length > before",
                    arg=before,
                    timeout=8000,
                )
                clicked = True
        except:
            pass

        page.evaluate("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(0.9)

        if count == prev_count and not clicked:
            break
        prev_count = count

    links = sorted(list(links_set))
    print(f" Zebrano linków: {len(links)}")
    return links


# ========= PARSER =========

def _extract_json_ld(soup: BeautifulSoup) -> Dict[str, Any] | None:
    for tag in soup.find_all("script", {"type": "application/ld+json"}):
        try:
            data = json.loads(tag.string or "")
        except Exception:
            continue
        if isinstance(data, dict) and data.get("@type") == "JobPosting":
            org = data.get("hiringOrganization") or {}
            loc = (data.get("jobLocation") or {}).get("address") or {}
            return {
                "title": normalize_ws(data.get("title", "")),
                "company": normalize_ws(org.get("name", "")),
                "location": normalize_ws(loc.get("addressLocality", "")),
                "offer_description": normalize_ws(
                    re.sub("<[^>]+>", " ", data.get("description", "") or "")
                ),
            }
    return None


def _find_section(soup: BeautifulSoup, labels) -> str:
    for label in labels:
        for hn in ["h2", "h3", "h4"]:
            for h in soup.select(hn):
                if label.lower() in (h.get_text(" ", strip=True) or "").lower():
                    sib = h.find_next_sibling()
                    if sib:
                        txt = sib.get_text("\n", strip=True)
                        if txt:
                            return txt.strip()
    return ""


class NfjScraper(ConfigurableJobScraper):
    """
    NFJ ma customowe zachowanie:
    - własne cookies/geo
    - przycisk "Pokaż kolejne oferty"
    Dlatego nadpisujemy scrape_links() tak, by użyć sprawdzonej logiki.
    """

    def scrape_links(self) -> list[str]:
        print(f"[NFJ] Start zbierania linków dla: {self.cfg.name}")
        self.browser.open()
        try:
            page = self.browser.new_page()

            # geo killer jak w Twoim starym kodzie
            try:
                install_geo_killer(page)
            except Exception as e:
                print("install_geo_killer error:", e)

            # dodatkowe localStorage (jak w starym skrypcie)
            page.add_init_script(
                """
                try {
                    localStorage.setItem('nfj-country', 'PL');
                    localStorage.setItem('country', 'PL');
                    localStorage.setItem('geoDismissed', '1');
                } catch (e) {}
                """
            )

            links = collect_listing_links_like_old(page, str(self.cfg.base_url))
            print(f"[NFJ] Zebrano linków (wewnątrz scraper): {len(links)}")
            return links
        finally:
            self.browser.close()

    def parse_offer_html(self, html: str, url: str) -> dict:
        soup = BeautifulSoup(html, "lxml")

        base = _extract_json_ld(soup) or {}

        def sel(css: str) -> str:
            el = soup.select_one(css) if css else None
            return normalize_ws(el.get_text(" ", strip=True)) if el else ""

        title = base.get("title") or sel(self.cfg.fields.title)
        company = base.get("company") or sel(self.cfg.fields.company or "")
        location = base.get("location") or sel(self.cfg.fields.location or "")
        salary_raw = sel(self.cfg.fields.salary or "")

        must = _find_section(soup, H["must"])
        nice = _find_section(soup, H["nice"])
        resp = _find_section(soup, H["resp"])
        off = base.get("offer_description") or _find_section(soup, H["off"])

        techs = [
            normalize_ws(li.get_text(" ", strip=True))
            for li in soup.select(self.cfg.fields.tech_stack or "")
        ]

        salaries = [Salary(raw=salary_raw)] if salary_raw else []

        return {
            "url": url,
            "title": title or "Brak tytułu",
            "company": company or None,
            "location": location or None,
            "salaries": salaries,
            "must_have": must or None,
            "nice_to_have": nice or None,
            "responsibilities": resp or None,
            "offer_description": off or None,
            "tech_stack": techs,
        }
