import os
import json
import base64
import functions_framework
from google.cloud import bigquery

BQ_TABLE = os.environ["JOBS_RAW_TABLE"]  # np. laborinsight-data.laborinsight.jobs_raw
bq = bigquery.Client()

@functions_framework.cloud_event
def export_jobs_raw(event):
    b64 = event.data["message"]["data"]
    rec = json.loads(base64.b64decode(b64))

    row = {
        "source": rec["source"],
        "payload": rec["payload"],          # typ JSON w BQ
        "ingested_at": rec["ingested_at"],
        "fingerprint": rec.get("fingerprint")
    }
    # insertId = fingerprint → idempotencja (bez duplikatów przy retrach)
    errors = bq.insert_rows_json(BQ_TABLE, [{"json": row, "insertId": rec.get("fingerprint")}])
    if errors:
        print(f"BQ insert errors: {errors}")
