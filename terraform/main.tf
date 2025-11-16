# 1. Dość stara wersja providera, juz dawno jest 7.x, ale pod kątem samego działania nic to dla Ciebie nie zmienia. W pracy po prostu pilnuje się, aby odpalając nowe projekty korzystać z możliwie najnowszej wersji
# 2. Pewnie w tym projekcie nie ma to takiego znaczenia, ale tak szczerze to rzadko kiedy się pisze Terraformy takie stand alone. Standardem jest tworzenie reużywalnych modułów (https://developer.hashicorp.com/terraform/language/modules). Moduły to taka powtarzalna logika, którą można porównać do bibliotek w programowaniu.
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }
}
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.gcp_credentials
}
