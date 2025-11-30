resource "google_colab_runtime_template" "protocol_runtime" {
  display_name = "protocol-scraper-runtime"
  location     = "europe-west4"

  machine_spec {
    machine_type = "e2-standard-4"
  }

  # data_persistent_disk_spec {
  #   disk_type    = "pd-standard" 
  #   disk_size_gb = 20 
  #   # sprawdzic to. byc moze przy kazdej inicjacji bedzie tworzyc nowy dysk. wysiwietlal sie w przezszlosci blad error code 8 "Quota'SSD_TOTAL_GB' exceeded". 
  #   # Byc moze problem jest natury eu-central. doczytac czym jest ta quota (nie wiem)
  # }

  network_spec {
    enable_internet_access = true
  }

  depends_on = [
    google_project_service.enabled["aiplatform.googleapis.com"],
    google_project_service.enabled["compute.googleapis.com"]
  ]
}
