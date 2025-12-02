# FM: # 1. w outputach podobnie jak przy variables dobrą praktyką jest dawanie opisu

output "pubsub_topic_jobs_raw" {
  value = google_pubsub_topic.jobs_raw.id
}


output "extract_function_uri" {
  value = google_cloudfunctions2_function.extract_justjoinit.service_config[0].uri
}

output "justjoinit_bronze_table" {
  value = "${var.project_id}.${google_bigquery_dataset.laborinsight.dataset_id}.${google_bigquery_table.bronze_justjoinit_jobs.table_id}"
}
output "solidjobs_bronze_table" {
  value = "${var.project_id}.${google_bigquery_dataset.laborinsight.dataset_id}.${google_bigquery_table.bronze_solidjobs_jobs.table_id}"
}
output "theprotocol_bronze_table" {
  value = "${var.project_id}.${google_bigquery_dataset.laborinsight.dataset_id}.${google_bigquery_table.bronze_theprotocolit_jobs.table_id}"
}
# <--------------- brzydki sposób interpolacji, tak optycznie mi się nie podoba i wygląda jak za starego Terraforma. Z ciekawości zapytałem AI, 
# jakby to zapisał i podpowiedział coś takiego 'value       = format("%s.%s.%s", var.project_id, google_bigquery_dataset.laborinsight.dataset_id, google_bigquery_table.jobs_raw.table_id)', ale nie mam 100% pewności działania, bo nie testowałem :)

output "colab_notebook_gcs_uri" {
  value = "gs://${google_storage_bucket_object.protocol_notebook.bucket}/${google_storage_bucket_object.protocol_notebook.name}"
}

output "colab_runtime_template_id" {
  value = google_colab_runtime_template.protocol_runtime.id
}

output "colab_schedule_name" {
  value = google_colab_schedule.protocol_daily.name
}
