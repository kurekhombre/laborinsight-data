data "google_project" "current" {}

locals {
  cf_sa_email = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}