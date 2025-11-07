
resource "google_cloud_scheduler_job" "nfj_scraper_daily" {
  name        = "nfj-scraper-daily"
  description = "Run NFJ scraper daily"
  schedule    = "0 6 * * *" # codziennie 06:00
  time_zone   = "Europe/Warsaw"

  http_target {
    uri         = "https://${google_cloud_run_v2_job.nfj_scraper.location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.nfj_scraper.name}:run"
    http_method = "POST"
    oauth_token {
      service_account_email = local.cf_sa_email
    }
  }

  depends_on = [google_cloud_run_v2_job.nfj_scraper]
}
