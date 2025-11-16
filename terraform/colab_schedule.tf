resource "google_colab_schedule" "protocol_daily" {
  display_name             = "protocol-scraper-daily"
  location                 = var.colab_location
  max_concurrent_run_count = 1
  cron                     = "TZ=Europe/Warsaw 0 7 * * *"

  create_notebook_execution_job_request {
    notebook_execution_job {
      display_name = "protocol-scraper-execution"

      gcs_notebook_source {
        uri        = "gs://${google_storage_bucket_object.protocol_notebook.bucket}/${google_storage_bucket_object.protocol_notebook.name}"
        generation = google_storage_bucket_object.protocol_notebook.generation
      }

      notebook_runtime_template_resource_name = google_colab_runtime_template.protocol_runtime.id

      gcs_output_uri = "gs://${google_storage_bucket.protocol_notebooks.name}/outputs"

      service_account = var.colab_service_account_email
    }
  }

  depends_on = [
    google_colab_runtime_template.protocol_runtime,
    google_storage_bucket.protocol_notebooks,
    google_storage_bucket_object.protocol_notebook,
  ]
}
