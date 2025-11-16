resource "google_colab_runtime_template" "protocol_runtime" {
  display_name = "protocol-scraper-runtime"
  location     = var.colab_location

  machine_spec {
    machine_type = "e2-standard-4"
  }

  network_spec {
    enable_internet_access = true
  }

  depends_on = [
    google_project_service.enabled["aiplatform.googleapis.com"],
    google_project_service.enabled["compute.googleapis.com"]
  ]
}
