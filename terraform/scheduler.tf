data "google_project" "current" {}
locals { cf_sa_email = "${data.google_project.current.number}-compute@developer.gserviceaccount.com" }

resource "google_cloud_scheduler_job" "jjit_extract_daily" {
  name        = "jjit-extract-daily"
  description = "Call extract-justjoinit once per day"
  schedule    = "0 7 * * *"          # 07:00 Europe/Warsaw
  time_zone   = "Europe/Warsaw"

  http_target {
    uri         = google_cloudfunctions2_function.extract_justjoinit.url
    http_method = "POST"
    oauth_token {
      service_account_email = local.cf_sa_email
    }
  }

  depends_on = [google_cloudfunctions2_function.extract_justjoinit]
}
