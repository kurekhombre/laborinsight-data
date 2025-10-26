resource "google_bigquery_data_transfer_config" "merge_jobs_everyday" {
  display_name           = "merge_jobs_curated"
  location               = "EU"
  data_source_id         = "scheduled_query"
  schedule               = "30 7 * * *"
  destination_dataset_id = google_bigquery_dataset.laborinsight.dataset_id

  params = {
    query = <<-EOT
      MERGE `laborinsight-data.laborinsight.jobs` T
      USING (
        SELECT
          fingerprint,
          source,
          JSON_VALUE(payload, '$.title') AS title,
          JSON_VALUE(payload, '$.companyName') AS company,
          JSON_VALUE(payload, '$.city') AS city,
          SAFE.TIMESTAMP(JSON_VALUE(payload, '$.publishedAt')) AS published_at,
          payload,
          TIMESTAMP(ingested_at) AS ingested_ts
        FROM `laborinsight-data.laborinsight.jobs_raw`
        WHERE DATE(ingested_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      ) S
      ON T.fingerprint = S.fingerprint
      
      WHEN MATCHED THEN
        UPDATE SET
          T.last_seen  = GREATEST(T.last_seen, S.ingested_ts),
          T.is_active  = TRUE,
          T.payload    = S.payload,
          T.title      = COALESCE(S.title, T.title),
          T.company    = COALESCE(S.company, T.company),
          T.city       = COALESCE(S.city, T.city),
          T.published_at = COALESCE(S.published_at, T.published_at)
      
      WHEN NOT MATCHED THEN
        INSERT (fingerprint, source, title, company, city, published_at, payload, first_seen, last_seen, is_active)
        VALUES (S.fingerprint, S.source, S.title, S.company, S.city, S.published_at, S.payload, S.ingested_ts, S.ingested_ts, TRUE);
    EOT
  }

  depends_on = [
    google_bigquery_table.jobs_curated,
    google_bigquery_table.jobs_raw
  ]
}
