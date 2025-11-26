# 1. w wielu miejsach przewija się odwołanie do 'google_bigquery_dataset.laborinsight.dataset_id' - można to zapisać ładniej przy pomocy 'locals'  (https://developer.hashicorp.com/terraform/language/block/locals). 

resource "google_bigquery_table" "jobs_curated" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "jobs"

  schema = jsonencode([
    { name = "fingerprint",  type = "STRING",    mode = "REQUIRED" },
    { name = "source",       type = "STRING",    mode = "REQUIRED" },
    { name = "title",        type = "STRING",    mode = "NULLABLE" },
    { name = "company",      type = "STRING",    mode = "NULLABLE" },
    { name = "city",         type = "STRING",    mode = "NULLABLE" },
    { name = "published_at", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "payload",      type = "JSON",      mode = "REQUIRED" },

    { name = "first_seen",   type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "last_seen",    type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "is_active",    type = "BOOL",      mode = "REQUIRED" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "last_seen"
  }

  clustering = ["source", "fingerprint"]
}
