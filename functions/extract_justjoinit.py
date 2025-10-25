import os
import json
import time
import hashlib
import requests
import functions_framework
from google.cloud import pubsub_v1

API_URL = "https://api.justjoin.it/v2/user-panel/offers/by-cursor"
TOPIC   = os.environ["PUBSUB_TOPIC"]
STEP    = int(os.getenv("ITEMS_PER_PAGE", "100"))
TIMEOUT = int(os.getenv("HTTP_TIMEOUT_SEC", "60"))

publisher = pubsub_v1.PublisherClient()

def iter_offers():
    """Generator: pobiera oferty strona po stronie i zwraca pojedyncze rekordy."""
    cursor = ""
    while True:
        url = f"{API_URL}?from={cursor}&itemsCount={STEP}&orderBy=DESC&sortBy=published"
        resp = requests.get(url, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        batch = data.get("data", []) or []
        for o in batch:
            yield o
        next_cursor = (data.get("meta") or {}).get("next", {}).get("cursor")
        if not next_cursor:
            break
        cursor = next_cursor

def _fingerprint(offer: dict) -> str:
    # stabilny klucz: preferuj guid/slug; fallback na tytuł+firma
    basis = str(
        offer.get("guid")
        or offer.get("slug")
        or (offer.get("title","") + "|" + offer.get("companyName",""))
    )
    return hashlib.sha1(basis.encode("utf-8")).hexdigest()

@functions_framework.http
def extract_justjoinit(_req):
    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    published = 0
    for offer in iter_offers():
        msg = {
            "source": "justjoinit",
            "payload": offer,          # surowy obiekt z API
            "ingested_at": now,
            "fingerprint": _fingerprint(offer)
        }
        # publikujemy jedną ofertę = jedna wiadomość
        publisher.publish(TOPIC, json.dumps(msg, ensure_ascii=False).encode("utf-8")).result()
        published += 1
    return (json.dumps({"published": published}), 200, {"Content-Type": "application/json"})
