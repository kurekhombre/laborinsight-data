resource "google_project_service" "enabled" {
  for_each = toset([
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "bigquery.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com", 
    "aiplatform.googleapis.com", 
  ])
  project = var.project_id
  service = each.key
}
