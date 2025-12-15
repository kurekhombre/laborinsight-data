MERGE INTO `laborinsight-data.laborinsight.silver_solidjobs_jobs` AS T
USING (
  WITH LatestRawData AS (
    SELECT
      payload,
      fingerprint AS job_key,
      ingested_at
    FROM `laborinsight-data.laborinsight.bronze_solidjobs_jobs`
    WHERE DATE(ingested_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      AND source = 'solidjobs'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY fingerprint ORDER BY ingested_at DESC) = 1
  ),

  Parsed AS (
    SELECT
      t1.job_key,
      t1.ingested_at,
      'Solid.jobs' AS source_name,

      TRIM(JSON_VALUE(t1.payload, '$.category')) AS category,
      TRIM(JSON_VALUE(t1.payload, '$.title'))    AS title,

      TRIM(
        REGEXP_REPLACE(
          JSON_VALUE(t1.payload, '$.company'),
          r'(?i)\s+(sp\.|spółka)\s+.*$',
          ''
        )
      ) AS company,

      COALESCE(TRIM(JSON_VALUE(t1.payload, '$.location')), 'Unknown') AS city,
      COALESCE(TRIM(JSON_VALUE(t1.payload, '$.seniority')), 'Other')  AS seniority,

      -- Solid często nie ma jawnego workplaceType -> ustawiamy Unknown
      'unknown' AS workplace,

      -- contracts: wymuszenie dokładnego typu jak w tabeli silver
      CAST(
        ARRAY(
          SELECT AS STRUCT
            CAST('unknown' AS STRING) AS type,
            CAST(
              LOWER(
                COALESCE(
