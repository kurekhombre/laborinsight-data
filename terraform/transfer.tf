# resource "google_bigquery_data_transfer_config" "merge_jobs_everyday" {
#   display_name           = "merge_jobs_curated"
#   location               = "EU"                     # zostaw "EU" (a nie "europe")
#   data_source_id         = "scheduled_query"
#   schedule               = "every day 07:30"        # <-- NIE cron!
#   destination_dataset_id = google_bigquery_dataset.laborinsight.dataset_id

#   params = {
#     query = file("${path.module}/support/sql/merge_jobs.sql")
#   }

#   depends_on = [
#     google_bigquery_table.jobs_curated,
#     google_bigquery_table.jobs_raw,
#     google_project_service.enabled["bigquery.googleapis.com"]
#   ]

# }

resource "google_bigquery_data_transfer_config" "merge_justjoinit_silver" {
  display_name           = "Merge_JustJoinIT_to_Silver"
  location               = "EU"
  data_source_id         = "scheduled_query"
  
  schedule               = "every day 08:30" 
  
  destination_dataset_id = google_bigquery_dataset.laborinsight.dataset_id

  params = {
    query = file("${path.module}/support/sql/merge_justjoinit_silver.sql") 
  }

  depends_on = [
    google_bigquery_table.silver_justjoinit_jobs,
    google_bigquery_table.justjoinit_categories,
  ]
}