import os
import json
import base64
import functions_framework
from google.cloud import bigquery

bq = bigquery.Client()

try:
    TABLE_MAP = json.loads(os.getenv("TABLE_MAP"))
except Exception as e:
    print(f"Error loading TABLE_MAP from environment: {e}")
    TABLE_MAP = {}

@functions_framework.cloud_event
def export_jobs_raw(event):

    b64 = event.data["message"]["data"]
    rec = json.loads(base64.b64decode(b64))
    
    source = rec.get("source")
    
    target_table_id = TABLE_MAP.get(source) 
    
    if not target_table_id:
        print(f"ERROR: Missing target table configuration for source: {source}")
        return 

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
            target_table_id,
            [row],
            row_ids=[insert_id] if insert_id else None
        )
        if errors:
            print(f"BQ insert errors for {target_table_id}: {errors}")
        else:
            print(f"BQ insert OK for {target_table_id}")
    except Exception as e:
        print(f"BQ insert exception for {target_table_id}: {e}")
