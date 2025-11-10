from typing import List, Tuple
from .config import SiteConfig
from .models import JobOffer
from .browser_adapter import AbstractBrowserAdapter
from .pagination import NextPageStrategy, InfiniteScrollStrategy


class ConfigurableJobScraper:
    """
    Template Method:
      - scrape_links()
      - scrape_offers_from_html()
    Konkretne portale nadpisują parse_offer_html().
    """

    def __init__(self, cfg: SiteConfig, browser: AbstractBrowserAdapter):
        self.cfg = cfg
        self.browser = browser

        if cfg.pagination.mode == "next":
            self.pagination = NextPageStrategy()
        else:
            self.pagination = InfiniteScrollStrategy()

    # ----- LISTING (Playwright) -----

    def scrape_links(self) -> List[str]:
        self.browser.open()
        try:
            page = self.browser.new_page()
            if self.cfg.geo_fix_script:
                try:
                    page.add_init_script(self.cfg.geo_fix_script)
                except:
                    pass

            self.browser.goto(page, str(self.cfg.base_url))

            if self.cfg.cookie_accept_selector:
                self.browser.click_if_exists(page, self.cfg.cookie_accept_selector)

            for sel in self.cfg.extra_click_selectors:
                self.browser.click_if_exists(page, sel)

            return self.pagination.collect_links(page, self.browser, self.cfg)
        finally:
            self.browser.close()

    # ----- DETAILS (httpx/async) -----

    def scrape_offers_from_html(self, pages: List[Tuple[str, str]]) -> List[JobOffer]:
        offers: List[JobOffer] = []
        total = len(pages)

        for idx, (url, html) in enumerate(pages, start=1):
            if not html:
                # brak HTML → np. błąd pobierania
                print(f"[{idx}/{total}] FAIL {url} (brak HTML)")
                offers.append(JobOffer(
                    url=url,
                    title="",
                    error="no_html",
                ))
                continue

            try:
                data = self.parse_offer_html(html, url)
                offer = JobOffer(**data)
                offers.append(offer)
                print(f"[{idx}/{total}] OK   {url} — {offer.title[:80]}")
            except Exception as e:
                print(f"[{idx}/{total}] ERR  {url} — {e}")
                offers.append(JobOffer(
                    url=url,
                    title="",
                    error=str(e),
                ))

        return offers


    # ----- hook do nadpisania -----

    def parse_offer_html(self, html: str, url: str) -> dict:
        raise NotImplementedError("Implement parse_offer_html() w klasie serwisu.")
