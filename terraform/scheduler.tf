data "google_project" "current" {}
locals {
  cf_sa_email = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_cloud_scheduler_job" "jjit_extract_daily" {
  name        = "jjit-extract-daily"
  description = "Call extract-justjoinit once per day"
  schedule    = "0 7 * * *"        # 07:00 Europe/Warsaw (cron dla Cloud Scheduler)
  time_zone   = "Europe/Warsaw"

  http_target {
    uri         = google_cloudfunctions2_function.extract_justjoinit.url
    http_method = "POST"
    # OIDC jest zalecane dla CF Gen2 (Cloud Run)
    oidc_token {
      service_account_email = local.cf_sa_email
    }
  }

  depends_on = [
    google_cloudfunctions2_function.extract_justjoinit,
    google_project_service.enabled["cloudscheduler.googleapis.com"]  # << ważne
  ]
}
