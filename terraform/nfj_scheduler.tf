data "google_project" "current" {}

locals {
  cf_sa_email = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Uprawnienia: job musi móc publikować do Pub/Sub
resource "google_pubsub_topic_iam_member" "jobs_raw_publisher_nfj" {
  topic  = google_pubsub_topic.jobs_raw.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${local.cf_sa_email}"
}

resource "google_cloud_run_v2_job" "nfj_scraper" {
  name     = "nfj-scraper"
  location = var.region

  template {
    template {
      containers {
        # obraz zbudujesz z GitHub Actions (patrz sekcja 5)
        image = "europe-central2-docker.pkg.dev/${var.project_id}/laborinsight/nfj-scraper:latest"

        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.jobs_raw.id
        }

        # opcjonalnie: możesz ograniczyć do jednego poziomu
        # env {
        #   name  = "LEVEL"
        #   value = "mid"
        # }
      }

      service_account = local.cf_sa_email
    }
  }

  depends_on = [
    google_artifact_registry_repository.laborinsight,
    google_pubsub_topic.jobs_raw,
    google_pubsub_topic_iam_member.jobs_raw_publisher_nfj,
  ]
}
