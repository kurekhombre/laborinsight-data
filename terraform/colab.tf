resource "google_storage_bucket" "protocol_notebooks" {
  name                        = "li-colab-notebooks-${var.project_id}"
  location                    = "europe-west4"
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.enabled["storage.googleapis.com"]
  ]
}

resource "google_storage_bucket_object" "protocol_notebook" {
  name   = "protocol_scraper.ipynb"
  bucket = google_storage_bucket.protocol_notebooks.name
  source = "${path.module}/support/notebooks/protocol_scraper.ipynb"
  source = file("${path.module}/support/sql/merge_jobs.sql"
}
