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

variable "colab_location" {
  type        = string
  description = "Region for Colab Enterprise resources"
  default     = "europe-central2"
}

variable "colab_service_account_email" {
  type        = string
  description = "Service account email used to run Colab notebook executions"
}