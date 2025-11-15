import asyncio
import random
import json
import logging
import time
from datetime import datetime

import requests
from bs4 import BeautifulSoup, BeautifulSoup as BS
from playwright.async_api import async_playwright

SITEMAP_URL = "https://static.theprotocol.it/sitemaps/CurrentOffers/SiteMapJobOffers1.xml"
CONCURRENCY = 5

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
DATA_FILENAME = f"protocol_data_{timestamp}.jsonl"
LOG_FILENAME = f"protocol_log_{timestamp}.log"

logger = logging.getLogger("protocol_scraper")
logger.setLevel(logging.INFO)

formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)

file_handler = logging.FileHandler(LOG_FILENAME, encoding="utf-8")
file_handler.setFormatter(formatter)

logger.handlers.clear()
logger.addHandler(console_handler)
logger.addHandler(file_handler)

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/129.0.0.0 Safari/537.36"
    )
}


def parse_list(section):
    if not section:
        return None
    items = []
    for li in section.select("li"):
        t = li.get_text(strip=True)
        if t:
            items.append(t)
    return items if items else None


def extract_title(soup: BeautifulSoup):
    tag = soup.find("h1")
    return tag.get_text(strip=True) if tag else None


def extract_company(soup: BeautifulSoup):
    tag = soup.select_one('[data-test="text-offerEmployer"]')
    if not tag:
        return None

    span = tag.find("span")
    if span:
        span.extract()

    return tag.get_text(strip=True)

def extract_salary(soup: BeautifulSoup):
    container = soup.select_one('[data-test="text-salary-value"]')
    if not container:
        return None

    if container.get("data-is-secondary") == "true":
        return container.get_text(strip=True)

    salary_value = container.select_one('[data-test="text-contractSalary"]')
    salary_units = container.select_one('[data-test="text-contractUnits"]')
    salary_time = container.select_one('[data-test="text-contractTimeUnits"]')

    parts = []
    if salary_value:
        parts.append(salary_value.get_text(" ", strip=True))
    if salary_units:
        parts.append(salary_units.get_text(" ", strip=True))
    if salary_time:
        parts.append(salary_time.get_text(" ", strip=True))

    return " ".join(parts) if parts else None


def extract_location(soup: BeautifulSoup):
    loc = soup.select_one('[data-test="text-primaryLocation"]')
    if loc:
        return loc.get_text(strip=True)

    loc2 = soup.select_one('[data-test="text-currentLocation1"]')
    if loc2:
        return loc2.get_text(strip=True)

    return None


def extract_level(soup: BeautifulSoup):
    tag = soup.select_one('[data-test="content-positionLevels"]')
    if not tag:
        return None

    txt = tag.get_text(strip=True).lower()
    if "/" in txt:
        return [x.strip() for x in txt.split("/")]
    return txt


def extract_requirements(soup: BeautifulSoup):
    result = {"expected": [], "optional": []}

    expected = soup.select_one('[data-test="section-requirements-expected"]')
    optional = soup.select_one('[data-test="section-requirements-optional"]')

    if expected:
        result["expected"] = parse_list(expected) or []
    if optional:
        result["optional"] = parse_list(optional) or []

    return result


def extract_responsibilities(soup: BeautifulSoup):
    section = soup.select_one('[data-test="section-responsibilities"]')
    return parse_list(section)


def extract_offered_and_benefits(soup: BeautifulSoup):
    offered = soup.select_one('[data-test="section-offered"]')
    benefits = soup.select_one('[data-test="section-benefits"]')

    return {
        "offered": parse_list(offered),
        "benefits": parse_list(benefits),
    }


def extract_technologies(soup: BeautifulSoup):
    sections = []

    for h3 in soup.find_all("h3"):
        title = h3.get_text(strip=True).lower()
        container = h3.find_next("div")
        if not container:
            continue

        chips = container.select('[data-test="chip-technology"]')

        values = []
        for c in chips:
            if c.get("title"):
                values.append(c["title"].strip())
            else:
                t = c.get_text(strip=True)
                if t:
                    values.append(t)

        if values:
            sections.append(values)

    required = sections[0] if len(sections) > 0 else []
    nice = sections[1] if len(sections) > 1 else []

    return required, nice


def parse_offer(html: str, url: str):
    soup = BeautifulSoup(html, "lxml")

    title = extract_title(soup)
    company = extract_company(soup)
    location = extract_location(soup)
    level = extract_level(soup)
    salary = extract_salary(soup)
    tech_required, tech_nice = extract_technologies(soup)
    requirements = extract_requirements(soup)
    responsibilities = extract_responsibilities(soup)
    offered = extract_offered_and_benefits(soup)

    return {
        "title": title,
        "company": company,
        "location": location,
        "level": level,
        "salary": salary,
        "tech_required": tech_required,
        "tech_nice_to_have": tech_nice,
        "requirements": requirements,
        "responsibilities": responsibilities,
        "offered": offered,
        "url": url,
    }


async def fetch_offer(page, url: str, retries: int = 3):
    for attempt in range(retries):
        try:
            await asyncio.sleep(random.uniform(0.2, 1.1))
            await page.goto(url, timeout=60000, wait_until="domcontentloaded")
            html = await page.content()
            return parse_offer(html, url)
        except Exception as e:
            if attempt == retries - 1:
                logger.error(f"Fetch error for {url}: {e}")
                return {"url": url, "error": str(e)}
            await asyncio.sleep(1 + attempt)


async def scrape_all(urls):
    results = []

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(
            headless=True,
            args=["--disable-blink-features=AutomationControlled"],
        )

        semaphore = asyncio.Semaphore(CONCURRENCY)

        async def worker(url, idx, total):
            async with semaphore:
                page = await browser.new_page(user_agent=HEADERS["User-Agent"])
                data = await fetch_offer(page, url)
                await page.close()
                logger.info(
                    f"[{idx}/{total}] {data.get('title')} | "
                    f"{data.get('company')} | {data.get('location')} | {data.get('url')}"
                )

                return data

        tasks = [
            asyncio.create_task(worker(url, i + 1, len(urls)))
            for i, url in enumerate(urls)
        ]

        for task in asyncio.as_completed(tasks):
            results.append(await task)

        await browser.close()

    return results


def load_sitemap(url: str):
    logger.info("Fetching sitemap...")
    r = requests.get(url, headers=HEADERS)
    r.raise_for_status()
    xml = BS(r.text, "xml")
    urls = [loc.get_text() for loc in xml.find_all("loc")]
    logger.info(f"Found {len(urls)} URLs in sitemap")
    return urls


async def main():
    start = time.perf_counter()

    urls = load_sitemap(SITEMAP_URL)
    # urls = urls[:10] # LIMIT TO X(10)

    logger.info(f"Starting scraping of {len(urls)} offers...")

    results = await scrape_all(urls)

    with open(DATA_FILENAME, "w", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    elapsed = time.perf_counter() - start
    logger.info(f"Saved results to: {DATA_FILENAME}")
    logger.info(f"Exec time: {elapsed:.2f} s (~{elapsed/60:.1f} min)")
    logger.info(f"Saved logs to: {LOG_FILENAME}")

if __name__ == "__main__":
    asyncio.run(main())

    #await main()