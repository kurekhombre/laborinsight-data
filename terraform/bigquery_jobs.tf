# 1. w wielu miejsach przewija się odwołanie do 'google_bigquery_dataset.laborinsight.dataset_id' - można to zapisać ładniej przy pomocy 'locals'  (https://developer.hashicorp.com/terraform/language/block/locals). 

# resource "google_bigquery_table" "jobs_curated" {
#   dataset_id = google_bigquery_dataset.laborinsight.dataset_id
#   table_id   = "jobs"
#   deletion_protection = false
#   schema = jsonencode([
#     { name = "fingerprint",  type = "STRING",    mode = "REQUIRED" },
#     { name = "source",       type = "STRING",    mode = "REQUIRED" },
#     { name = "title",        type = "STRING",    mode = "NULLABLE" },
#     { name = "company",      type = "STRING",    mode = "NULLABLE" },
#     { name = "city",         type = "STRING",    mode = "NULLABLE" },
#     { name = "published_at", type = "TIMESTAMP", mode = "NULLABLE" },
#     { name = "payload",      type = "JSON",      mode = "REQUIRED" },

#     { name = "first_seen",   type = "TIMESTAMP", mode = "REQUIRED" },
#     { name = "last_seen",    type = "TIMESTAMP", mode = "REQUIRED" },
#     { name = "is_active",    type = "BOOL",      mode = "REQUIRED" }
#   ])

#   time_partitioning {
#     type  = "DAY"
#     field = "last_seen"
#   }

#   clustering = ["source", "fingerprint"]
# }
# SILVER

# JAJA TUTAJ BYŁy. AI ZROBIŁO SWOJE

locals {
  # Pełna, jawna definicja schematu tabeli Silver. 
  # Używamy jej, aby móc się do niej odwołać w bloku 'lifecycle' (replace_triggered_by).
  justjoinit_silver_schema = [
    { name = "job_key",      type = "STRING",    mode = "REQUIRED" },
    { name = "ingested_at",  type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "source_name",  type = "STRING",    mode = "REQUIRED" },
    
    { name = "category",     type = "STRING",    mode = "NULLABLE" },
    { name = "title",        type = "STRING",    mode = "NULLABLE" },
    { name = "company",      type = "STRING",    mode = "NULLABLE" },
    { name = "city",         type = "STRING",    mode = "NULLABLE" },
    { name = "seniority",    type = "STRING",    mode = "NULLABLE" },
    { name = "workplace",    type = "STRING",    mode = "NULLABLE" },

    # Poprawne Tablice Struktur (contracts)
    { 
      name = "contracts", 
      type = "STRUCT",        
      mode = "REPEATED",       
      fields = [
        { name = "type",       type = "STRING",  mode = "NULLABLE" },
        { name = "unit",       type = "STRING",  mode = "NULLABLE" },
        { name = "salary_min", type = "NUMERIC", mode = "NULLABLE" },
        { name = "salary_max", type = "NUMERIC", mode = "NULLABLE" },
        { name = "is_gross",   type = "BOOLEAN", mode = "NULLABLE" }
      ]
    },

    # Poprawne Tablice Stringów (tech_stack)
    { 
      name = "tech_stack",   
      type = "STRING",         
      mode = "REPEATED"        
    },

    { name = "original_url", type = "STRING",    mode = "NULLABLE" },
  ]
}

# -----------------------------------------------------------------------------
# Zasób Wyzwalający (Null Resource)
# Stosujemy go jako pośrednika, aby 'replace_triggered_by' mógł wykryć zmianę schematu.
# -----------------------------------------------------------------------------
resource "null_resource" "trigger_silver_schema_update" {
  # Używamy hashowania md5 na schemacie, aby za każdym razem, gdy zmienimy schemat, 
  # ten zasób został uznany za zmieniony.
  triggers = {
    schema_hash = md5(jsonencode(local.justjoinit_silver_schema))
  }
}

# -----------------------------------------------------------------------------
# Tabela BigQuery (Silver JustJoinIT Jobs)
# -----------------------------------------------------------------------------
resource "google_bigquery_table" "silver_justjoinit_jobs" {
  dataset_id = google_bigquery_dataset.laborinsight.dataset_id
  table_id   = "silver_justjoinit_jobs"
  deletion_protection = false

  # Jawne ustawienie opcjonalnych pól, aby zapobiec błędom 'null' w dostawcy
  description = "Tabela Silver dla JustJoinIT po transformacji i wzbogaceniu."
  friendly_name = "Silver JustJoinIT Jobs"
  labels = {
    layer = "silver"
    source = "justjoinit"
  }
  
  # Jawne wyłączenie filtra partycji (przeniesione z bloku time_partitioning)
  require_partition_filter = false 

  # Użycie zmiennej lokalnej dla definicji schematu
  schema = jsonencode(local.justjoinit_silver_schema)

  time_partitioning {
    type  = "DAY"
    field = "ingested_at" 
  }
  clustering = ["job_key", "city", "category"]
  
  # =========================================================
  # BLOK LIFE CYCLE (Omija błędy dostawcy i wymusza re-kreację)
  # =========================================================
  lifecycle {
    # Poprawna referencja: Odwołuje się do zasobu null_resource, a nie do locals.
    replace_triggered_by = [
      null_resource.trigger_silver_schema_update
    ]
    
    # Ignorowanie atrybutów tylko do odczytu, które powodowały niespójności planu
    ignore_changes = [
      creation_time,
      last_modified_time,
      num_bytes,
      num_long_term_bytes,
      num_rows,
      self_link,
      type,
      etag,
      location,
      max_staleness,
      generated_schema_columns
    ]
  }
}