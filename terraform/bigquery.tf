resource "google_bigquery_dataset" "laborinsight" {
  dataset_id = "laborinsight"
  location   = "EU"

  depends_on = [
    google_project_service.enabled["bigquery.googleapis.com"]
  ]
}

# resource "google_bigquery_table" "jobs_raw" {
#   dataset_id = google_bigquery_dataset.laborinsight.dataset_id
#   table_id   = "jobs_raw"
#   deletion_protection = false # <--- JAWNIE ustaw na FALSE
#   schema = jsonencode([
#     { name = "source",      type = "STRING",    mode = "REQUIRED" },
#     { name = "payload",     type = "JSON",      mode = "REQUIRED" }, # sprawdzic
#     { name = "ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
#     { name = "fingerprint", type = "STRING",    mode = "NULLABLE" }
#   ])

#   time_partitioning { #yyyymmdd - poczytać o partycjonowaniu i jego strategiach
#     type  = "DAY"
#     field = "ingested_at" 
#   }
#   clustering = ["source"]

#   depends_on = [
#     google_project_service.enabled["bigquery.googleapis.com"]
#   ]
# }

# Tabela Bronze dla Just Join IT
resource "google_bigquery_table" "bronze_justjoinit_jobs" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "bronze_justjoinit_jobs"

  schema = jsonencode([
    { name = "source",      type = "STRING",    mode = "REQUIRED" },
    { name = "payload",     type = "JSON",      mode = "REQUIRED" },
    { name = "ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "fingerprint", type = "STRING",    mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "ingested_at" 
  }
  clustering = ["source"]
}

# Tabela Bronze dla SolidJobs
resource "google_bigquery_table" "bronze_solidjobs_jobs" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "bronze_solidjobs_jobs"

  schema = google_bigquery_table.bronze_justjoinit_jobs.schema // Używamy tego samego schematu
  
  time_partitioning {
    type  = "DAY"
    field = "ingested_at" 
  }
  clustering = ["source"]
}

# Tabela Bronze dla The Protocol IT
resource "google_bigquery_table" "bronze_theprotocolit_jobs" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "bronze_theprotocolit_jobs"

  schema = google_bigquery_table.bronze_justjoinit_jobs.schema // Używamy tego samego schematu

  time_partitioning {
    type  = "DAY"
    field = "ingested_at" 
  }
  clustering = ["source"]
}
