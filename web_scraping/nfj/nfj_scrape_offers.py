#!/usr/bin/env python3
import sys
import json
from pathlib import Path
import asyncio
from datetime import datetime

from job_scraper.fetcher_async import fetch_many
from sites.nfj import nfj_site_config, NfjScraper
from job_scraper.browser_adapter import PlaywrightAdapter

LEVELS = ["trainee", "junior", "mid", "senior"]


async def main_async(level: str):
    cfg = nfj_site_config(level)
    scraper = NfjScraper(cfg, PlaywrightAdapter())

    out_dir = Path("output")
    out_dir.mkdir(exist_ok=True)

    candidates = sorted(out_dir.glob(f"nfj_links_{level}_*.json"))
    if not candidates:
        print(f"No link files found for {level}")
        return

    links_path = candidates[-1]
    print(f"▶ Using link file: {links_path.name}")

    raw = json.loads(links_path.read_text(encoding="utf-8"))

    if isinstance(raw, dict) and "links" in raw:
        links = raw["links"]
        collected_at = raw.get("collected_at")
    else:
        links = raw
        collected_at = None

    links = [u for u in links if isinstance(u, str) and u.startswith("http")]
    if not links:
        print("No links to process.")
        return

    print(f"▶ Fetching {len(links)} offers for {level}")
    pages = await fetch_many(links, concurrency=6)

    offers = scraper.scrape_offers_from_html(pages)

    date_str = datetime.now().strftime("%Y-%m-%d")

    payload = {
        "level": level,
        "collected_at": collected_at,
        "scraped_at": date_str,
        "offers": [o.model_dump(mode="json") for o in offers],
    }

    out_json = out_dir / f"nfj_offers_{level}_{date_str}.json"
    out_json.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Saved offers JSON to: {out_json.resolve()}")
    print(f"collected_at: {collected_at}")
    print(f"scraped_at:   {date_str}")


def main():
    if len(sys.argv) < 2 or sys.argv[1].lower() not in LEVELS:
        print(f"Usage: python -m scripts.nfj_scrape_offers <level>")
        print(f"Levels: {', '.join(LEVELS)}")
        sys.exit(1)

    level = sys.argv[1].lower()
    asyncio.run(main_async(level))


if __name__ == "__main__":
    main()
