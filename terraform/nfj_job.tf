resource "google_cloud_run_v2_job" "nfj_scraper" {
  name     = "nfj-scraper"
  location = var.region

  template {
    template {
      containers {
        image = "europe-central2-docker.pkg.dev/${var.project_id}/laborinsight/nfj-scraper:latest"

        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.jobs_raw.id
        }
      }
      service_account = local.cf_sa_email
    }
  }
}
