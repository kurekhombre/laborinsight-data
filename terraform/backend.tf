terraform {
  backend "gcs" {
    bucket = "laborinsight-tfstate"
    prefix = "terraform/state"
  }
}
