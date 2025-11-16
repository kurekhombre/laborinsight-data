# 1. w outputach podobnie jak przy variables dobrą praktyką jest dawanie opisu

output "pubsub_topic_jobs_raw" {
  value = google_pubsub_topic.jobs_raw.id
}

output "extract_function_uri" {
  value = google_cloudfunctions2_function.extract_justjoinit.service_config[0].uri
}

output "jobs_raw_table" {
  value = "${var.project_id}.${google_bigquery_dataset.laborinsight.dataset_id}.${google_bigquery_table.jobs_raw.table_id}" <--------------- brzydki sposób interpolacji, tak optycznie mi się nie podoba i wygląda jak za starego Terraforma. Z ciekawości zapytałem AI, jakby to zapisał i podpowiedział coś takiego 'value       = format("%s.%s.%s", var.project_id, google_bigquery_dataset.laborinsight.dataset_id, google_bigquery_table.jobs_raw.table_id)', ale nie mam 100% pewności działania, bo nie testowałem :)
}
