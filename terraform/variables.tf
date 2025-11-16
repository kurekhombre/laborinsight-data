# 1. Dobrą praktyką jest dawanie opisu do wszystkich zmiennych i sortowanie ich alfabetycznie - https://developer.hashicorp.com/terraform/language/block/variable#description

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
