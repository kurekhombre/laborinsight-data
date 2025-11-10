#!/usr/bin/env python3
import subprocess
import sys
import time

LEVELS = ["trainee", "junior", "mid", "senior"]


def run(cmd):
    print(f"\n Running: {' '.join(cmd)}")
    start = time.time()
    result = subprocess.run(cmd)
    dur = time.time() - start

    if result.returncode != 0:
        print(f"✖ Command failed ({dur:.1f}s): {' '.join(cmd)}")
        sys.exit(result.returncode)

    print(f"✔ Done in {dur/60:.2f} min ({dur:.1f} s)")


def main():
    total_start = time.time()

    for level in LEVELS:
        print("\n" + "=" * 60)
        print(f"LEVEL: {level.upper()}")
        print("=" * 60)

        # 1) Collect links (zapisze nfj_links_{level}_YYYY-MM-DD.json)
        run([sys.executable, "-m", "scripts.nfj_collect_links", level])

        # 2) Scrape offers (użyje najnowszego pliku links dla levelu)
        run([sys.executable, "-m", "scripts.nfj_scrape_offers", level])

    total_dur = time.time() - total_start
    print("\n" + "=" * 60)
    print(f"ALL LEVELS DONE in {total_dur/60:.2f} min ({total_dur:.1f} s)")
    print("=" * 60)


if __name__ == "__main__":
    main()
