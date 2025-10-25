import os
import json
import base64
import functions_framework
from google.cloud import bigquery

bq = bigquery.Client()

@functions_framework.cloud_event
def export_jobs_raw(event):
    table = os.getenv("JOBS_RAW_TABLE")
    if not table:
        print("Missing env JOBS_RAW_TABLE")
        return

    # dekodowanie wiadomości Pub/Sub
    b64 = event.data["message"]["data"]
    rec = json.loads(base64.b64decode(b64))

    # przygotowanie wiersza zgodnego ze schemą
    row = {
        "source": rec["source"],
        "payload": rec["payload"],          # kolumna typu JSON
        "ingested_at": rec["ingested_at"],  # RFC3339: 2025-10-25T18:58:00Z — OK
        "fingerprint": rec.get("fingerprint")
    }

    # idempotencja: insertId przekazujemy jako row_ids (osobny argument)
    insert_id = rec.get("fingerprint") or None

    try:
        errors = bq.insert_rows_json(table, [row], row_ids=[insert_id] if insert_id else None)
        if errors:
            # wypisz w logu, żeby łatwo diagnozować pojedyncze rekordy
            print(f"BQ insert errors: {errors}")
        else:
            print("BQ insert ok")
    except Exception as e:
        print(f"BQ insert exception: {e}")
