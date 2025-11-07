resource "google_artifact_registry_repository" "laborinsight" {
  provider      = google
  project       = var.project_id
  location      = var.region
  repository_id = "laborinsight"
  description   = "Container images for LaborInsight jobs"
  format        = "DOCKER"
}
