import asyncio
import random
from typing import List, Tuple
import httpx


PER_REQUEST_DELAY = (0.3, 1.0)
REQ_TIMEOUT_S = 14
RETRIES = 5
BACKOFF_BASE_S = 1.2

UA_LIST = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0",
]


def make_headers():
    ua = random.choice(UA_LIST)
    return {
        "User-Agent": ua,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "pl-PL,pl;q=0.9,en;q=0.8",
        "Cache-Control": "no-cache",
        "Pragma": "no-cache",
        "DNT": "1",
    }


async def fetch_with_retries(url: str) -> Tuple[str | None, str | None]:
    last_err = None

    async def one_client(http2: bool):
        async with httpx.AsyncClient(http2=http2, timeout=REQ_TIMEOUT_S, follow_redirects=True) as client:
            await asyncio.sleep(random.uniform(*PER_REQUEST_DELAY))
            return await client.get(url, headers=make_headers())

    for attempt in range(1, RETRIES + 1):
        use_http2 = attempt <= (RETRIES - 2)
        try:
            r = await one_client(use_http2)
            if r.status_code in (403, 429) or r.status_code >= 500:
                last_err = f"http {r.status_code}"
            else:
                return r.text, None
        except httpx.HTTPError as e:
            last_err = f"net: {e}"

        sleep_s = BACKOFF_BASE_S * (2 ** (attempt - 1)) + random.uniform(0.2, 0.9)
        await asyncio.sleep(sleep_s)

    return None, (last_err or "failed")


async def fetch_many(urls: List[str], concurrency: int = 6) -> List[Tuple[str, str]]:
    sem = asyncio.Semaphore(concurrency)
    results: List[Tuple[str, str]] = []

    async def worker(url: str):
        async with sem:
            html, err = await fetch_with_retries(url)
        if html:
            results.append((url, html))
        else:
            # Możesz tu dopisać logowanie errorów
            results.append((url, ""))

    await asyncio.gather(*(worker(u) for u in urls))
    return results
