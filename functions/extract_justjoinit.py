import os
import json
import time
import hashlib
import requests
import functions_framework
from google.cloud import pubsub_v1

API_URL_DEFAULT = "https://api.justjoin.it/v2/user-panel/offers/by-cursor"

publisher = pubsub_v1.PublisherClient()

def iter_offers(api_url: str, step: int, timeout_sec: int):
    cursor = ""
    while True:
        url = f"{api_url}?from={cursor}&itemsCount={step}&orderBy=DESC&sortBy=published"
        resp = requests.get(url, timeout=timeout_sec)
        resp.raise_for_status()
        data = resp.json()
        batch = (data or {}).get("data", []) or []
        for o in batch:
            yield o
        next_cursor = (data.get("meta") or {}).get("next", {}).get("cursor")
        if not next_cursor:
            break
        cursor = next_cursor

def _fingerprint(offer: dict) -> str:
    basis = str(
        offer.get("guid")
        or offer.get("slug")
        or (offer.get("title","") + "|" + offer.get("companyName",""))
    )
    return hashlib.sha1(basis.encode("utf-8")).hexdigest()

@functions_framework.http
def extract_justjoinit(_req):
    topic = os.getenv("PUBSUB_TOPIC")
    if not topic:
        return ("Missing env PUBSUB_TOPIC", 500)

    api_url = os.getenv("JJI_API_URL", API_URL_DEFAULT)
    step = int(os.getenv("ITEMS_PER_PAGE", "100"))
    timeout_sec = int(os.getenv("HTTP_TIMEOUT_SEC", "60"))

    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    published = 0

    for offer in iter_offers(api_url, step, timeout_sec):
        msg = {
            "source": "justjoinit",
            "payload": offer,
            "ingested_at": now,
            "fingerprint": _fingerprint(offer)
        }
        publisher.publish(topic, json.dumps(msg, ensure_ascii=False).encode("utf-8")).result()
        published += 1

    return (json.dumps({"published": published}), 200, {"Content-Type": "application/json"})
