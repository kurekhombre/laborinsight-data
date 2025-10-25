resource "google_bigquery_dataset" "laborinsight" {
  dataset_id = "laborinsight"
  location   = "EU"
}

resource "google_bigquery_table" "jobs_raw" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "jobs_raw"

  schema = jsonencode([
    { name = "source",      type = "STRING",    mode = "REQUIRED" },
    { name = "payload",     type = "JSON",      mode = "REQUIRED" },
    { name = "ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "fingerprint", type = "STRING",    mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "ingested_at"
  }

  clustering = ["source"]
}
