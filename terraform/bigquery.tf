resource "google_bigquery_dataset" "laborinsight" {
  dataset_id = "laborinsight"
  location   = "EU"
}

resource "google_bigquery_table" "jobs_raw" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "jobs_raw"
  schema     = file("./support/schemas/bq_jobs_raw_schema.json")

  time_partitioning {
    type  = "DAY"
    field = "ingested_at"
  }
}
