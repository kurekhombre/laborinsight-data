resource "google_pubsub_topic" "jobs_raw" {
  name = "jobs-raw"

  depends_on = [
    google_project_service.enabled["pubsub.googleapis.com"]
  ]
}