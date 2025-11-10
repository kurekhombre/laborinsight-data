#!/usr/bin/env python3
import sys
import json
from pathlib import Path
from datetime import datetime

from job_scraper.browser_adapter import PlaywrightAdapter
from sites.nfj import nfj_site_config, NfjScraper

LEVELS = ["trainee", "junior", "mid", "senior"]


def main():
    if len(sys.argv) < 2 or sys.argv[1].lower() not in LEVELS:
        print(f"Usage: python -m scripts.nfj_collect_links <level>")
        print(f"Levels: {', '.join(LEVELS)}")
        sys.exit(1)

    level = sys.argv[1].lower()
    cfg = nfj_site_config(level)
    browser = PlaywrightAdapter(headless=False)
    scraper = NfjScraper(cfg, browser)

    date_str = datetime.now().strftime("%Y-%m-%d")

    print(f"Collecting links for NFJ level={level}")
    links = scraper.scrape_links()
    print(f"Final collected links: {len(links)}")

    out_dir = Path("output")
    out_dir.mkdir(exist_ok=True)

    out_path = out_dir / f"nfj_links_{level}_{date_str}.json"

    payload = {
        "level": level,
        "collected_at": date_str,
        "links": links,
    }

    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Saved links JSON to: {out_path.resolve()}")


if __name__ == "__main__":
    main()
