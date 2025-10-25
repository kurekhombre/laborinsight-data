resource "google_pubsub_topic" "jobs_raw" {
  name = "jobs-raw"

  # Poczekaj aż API Pub/Sub będzie włączone
  depends_on = [
    google_project_service.enabled["pubsub.googleapis.com"]
  ]
}