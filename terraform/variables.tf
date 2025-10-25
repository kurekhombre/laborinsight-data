variable "project_id" {
  type = string
}
variable "region" {
  type    = string
  default = "europe-central2"
}
variable "gcp_credentials" {
  type      = string
  sensitive = true
}
