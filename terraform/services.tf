locals {
  gcp_services = [
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "storage.googleapis.com"
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.gcp_services)
  project  = var.project_id
  service  = each.key

  disable_on_destroy = false
}
