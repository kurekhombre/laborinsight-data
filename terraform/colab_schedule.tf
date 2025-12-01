resource "google_colab_schedule" "protocol_daily" {
  
  provider = google.west4
  location = "europe-west4"
  display_name             = "protocol-scraper-daily"
  max_concurrent_run_count = 1
  cron                     = "TZ=Europe/Warsaw 0 7 * * *"

  create_notebook_execution_job_request {
    notebook_execution_job {
      display_name = "protocol-scraper-execution"

      gcs_notebook_source {
        uri = "gs://${google_storage_bucket_object.protocol_notebook.bucket}/${google_storage_bucket_object.protocol_notebook.name}"
      }

      notebook_runtime_template_resource_name = google_colab_runtime_template.protocol_runtime.id
      gcs_output_uri                          = "gs://${google_storage_bucket.protocol_notebooks.name}/outputs"
      service_account                         = var.colab_service_account_email
    }
  }

  depends_on = [
    google_colab_runtime_template.protocol_runtime,
    google_storage_bucket.protocol_notebooks,
    google_storage_bucket_object.protocol_notebook
  ]
}

resource "google_colab_schedule" "solidjobs_daily" {
  provider                 = google.west4
  location                 = "europe-west4"
  display_name             = "solidjobs-scraper-daily"
  max_concurrent_run_count = 1
  cron                     = "TZ=Europe/Warsaw 0 7 * * *"

  create_notebook_execution_job_request {
    notebook_execution_job {
      display_name = "solidjobs-scraper-execution"

      gcs_notebook_source {
        uri = "gs://${google_storage_bucket_object.solidjobs_notebook.bucket}/${google_storage_bucket_object.solidjobs_notebook.name}"
      }

      notebook_runtime_template_resource_name = google_colab_runtime_template.solidjobs_runtime.id
      
      gcs_output_uri                          = "gs://${google_storage_bucket.protocol_notebooks.name}/outputs"
      service_account                         = var.colab_service_account_email
    }
  }

  depends_on = [
    google_colab_runtime_template.solidjobs_runtime,
    google_storage_bucket.protocol_notebooks,
    google_storage_bucket_object.solidjobs_notebook
  ]
}
