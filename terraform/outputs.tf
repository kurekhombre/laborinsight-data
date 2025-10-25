output "pubsub_topic_jobs_raw" {
  value = google_pubsub_topic.jobs_raw.id
}

output "extract_function_uri" {
  value = google_cloudfunctions2_function.extract_justjoinit.service_config[0].uri
}

output "jobs_raw_table" {
  value = "${var.project_id}.${google_bigquery_dataset.laborinsight.dataset_id}.${google_bigquery_table.jobs_raw.table_id}"
}
