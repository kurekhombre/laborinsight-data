


resource "google_storage_bucket" "functions_src" {
  name     = "li-func-src-${var.project_id}"
  location = var.region
}

data "archive_file" "functions_zip" {
  type        = "zip"
  source_dir  = "../functions"
  output_path = "${path.module}/functions.zip"
}

resource "google_storage_bucket_object" "functions_zip" {
  name   = "functions-${data.archive_file.functions_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_src.name
  source = data.archive_file.functions_zip.output_path
}

# 1 EXTRACT: HTTP CF -> Pub/Sub

resource "google_cloudfunctions2_function" "extract_justjoinit" {
  name     = "extract-justjoinit"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "extract_justjoinit"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_src.name
        object = google_storage_bucket_object.functions_zip.name
      }
    }
  }

  service_config {
    available_memory   = "512Mi"
    max_instance_count = 2
    environment_variables = {
      PUBSUB_TOPIC     = google_pubsub_topic.jobs_raw.id
      JJI_API_URL      = "https://api.justjoin.it/v2/user-panel/offers/by-cursor"
      ITEMS_PER_PAGE   = "100"
      HTTP_TIMEOUT_SEC = "60"
    }
    ingress_settings = "ALLOW_ALL"
    timeout_seconds  = 300

  }

  depends_on = [
    google_project_service.enabled["cloudfunctions.googleapis.com"],
    google_project_service.enabled["run.googleapis.com"],
    google_project_service.enabled["eventarc.googleapis.com"],
    google_project_service.enabled["cloudbuild.googleapis.com"],
    google_project_service.enabled["pubsub.googleapis.com"],
    google_storage_bucket_object.functions_zip
  ]
}

# 2 LOAD: Event CF (Pub/Sub) -> BigQuery RAW

resource "google_cloudfunctions2_function" "export_jobs_raw" {
  name     = "export-jobs-raw"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "export_jobs_raw"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_src.name
        object = google_storage_bucket_object.functions_zip.name
      }
    }
  }

  # Trigger Pub/Sub (jobs-raw)
  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.jobs_raw.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  service_config {
    available_memory   = "512Mi"
    max_instance_count = 4
    environment_variables = {
      JOBS_RAW_TABLE = "${var.project_id}.${google_bigquery_dataset.laborinsight.dataset_id}.${google_bigquery_table.jobs_raw.table_id}"
    }
    ingress_settings = "ALLOW_INTERNAL_ONLY"
    timeout_seconds  = 300

  }

  depends_on = [
    google_project_service.enabled["cloudfunctions.googleapis.com"],
    google_project_service.enabled["run.googleapis.com"],
    google_project_service.enabled["eventarc.googleapis.com"],
    google_project_service.enabled["cloudbuild.googleapis.com"],
    google_project_service.enabled["pubsub.googleapis.com"],
    google_project_service.enabled["bigquery.googleapis.com"],
    google_storage_bucket_object.functions_zip,
    google_pubsub_topic.jobs_raw,
    google_bigquery_table.jobs_raw
  ]
}
