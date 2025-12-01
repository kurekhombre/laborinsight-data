resource "google_colab_runtime_template" "protocol_runtime" {
  provider = google.west4
  location = "europe-west4"

  display_name = "protocol-scraper-runtime"

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

resource "google_colab_runtime_template" "solidjobs_runtime" {
  provider = google.west4
  location = "europe-west4"

  display_name = "solidjobs-scraper-runtime"

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