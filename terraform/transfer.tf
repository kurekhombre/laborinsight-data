resource "google_bigquery_data_transfer_config" "merge_jobs_everyday" {
  display_name           = "merge_jobs_curated"
  location               = "EU"
  data_source_id         = "scheduled_query"
  schedule               = "everyday"
  destination_dataset_id = google_bigquery_dataset.laborinsight.dataset_id

  params = {
    destination_table_name_template = "jobs"      # nie tworzy nowej, używamy MERGE
    write_disposition               = "WRITE_APPEND"
    query                           = file("${path.module}/support/sql/merge_jobs.sql")
  }

  depends_on = [
    google_bigquery_table.jobs_curated,
    google_bigquery_table.jobs_raw
  ]
}
