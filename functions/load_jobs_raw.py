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

    b64 = event.data["message"]["data"]
    rec = json.loads(base64.b64decode(b64))

    row = {
        "source": rec["source"],
        "payload": rec["payload"],          # BigQuery JSON typ
        "ingested_at": rec["ingested_at"],
        "fingerprint": rec.get("fingerprint")
    }

    # insertId = fingerprint → idempotencja
    errors = bq.insert_rows_json(table, [{"json": row, "insertId": rec.get("fingerprint")}])
    if errors:
        print(f"BQ insert errors: {errors}")
