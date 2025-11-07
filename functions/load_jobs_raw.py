import os
import json
import base64
import functions_framework
from google.cloud import bigquery

bq = bigquery.Client()

"""
feature z pub sub, który wrzuca bezpośrednio do bq (powinien być w free-tier)
"""

@functions_framework.cloud_event
def export_jobs_raw(event):
    table = os.getenv("JOBS_RAW_TABLE")
    if not table:
        print("Missing env JOBS_RAW_TABLE")
        return

    b64 = event.data["message"]["data"]
    rec = json.loads(base64.b64decode(b64))

    json_literal = json.dumps(rec["payload"], ensure_ascii=False)

    row = {
        "source": rec["source"],
        "payload": json_literal,
        "ingested_at": rec["ingested_at"],
        "fingerprint": rec.get("fingerprint"),
    }

    insert_id = rec.get("fingerprint") or None

    try:
        errors = bq.insert_rows_json(
            table,
            [row],
            row_ids=[insert_id] if insert_id else None
        )
        if errors:
            print(f"BQ insert errors: {errors}")
        else:
            print("BQ insert ok")
    except Exception as e:
        print(f"BQ insert exception: {e}")
