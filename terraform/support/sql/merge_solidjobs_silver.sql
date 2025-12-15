MERGE INTO 
  `laborinsight-data.laborinsight.silver_solid_jobs` AS T
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

      -- Solid ma salary_raw jako string; wyciągamy min/max + walutę (np. PLN), gdy się da.
      ARRAY(
        SELECT AS STRUCT
          'unknown' AS type,
          LOWER(COALESCE(REGEXP_EXTRACT(TRIM(JSON_VALUE(t1.payload, '$.salary_raw')), r'([A-Z]{3})\s*$'), 'pln')) AS unit,
          SAFE_CAST(REPLACE(REGEXP_EXTRACT(TRIM(JSON_VALUE(t1.payload, '$.salary_raw')), r'^\s*([\d\s]+)'), ' ', '') AS NUMERIC) AS salary_min,
          SAFE_CAST(REPLACE(REGEXP_EXTRACT(TRIM(JSON_VALUE(t1.payload, '$.salary_raw')), r'[–-]\s*([\d\s]+)'), ' ', '') AS NUMERIC) AS salary_max,
          NULL AS is_gross
      ) AS contracts,

      ARRAY(
        SELECT JSON_VALUE(skill)
        FROM UNNEST(JSON_QUERY_ARRAY(t1.payload, '$.tech_stack')) AS skill
      ) AS tech_stack,

      TRIM(JSON_VALUE(t1.payload, '$.url')) AS original_url,

      TRIM(JSON_VALUE(t1.payload, '$.must_have'))          AS must_have,
      TRIM(JSON_VALUE(t1.payload, '$.responsibilities'))   AS responsibilities,
      TRIM(JSON_VALUE(t1.payload, '$.offer_description'))  AS offer_description
    FROM LatestRawData t1
    WHERE TRIM(JSON_VALUE(t1.payload, '$.title')) IS NOT NULL
  )

  SELECT *
  FROM Parsed
  WHERE category IS NOT NULL
    AND LOWER(category) != 'null'
    AND category NOT IN (
    'Rekruter',
    'Sprzedaż B2B',
    'Transport i Spedycja',
    'Pozostali specjaliści sprzedaży',
    'Marketing',
    'Księgowość',
    'Zarządzanie',
    'Prawo i Administracja',
    'Analityka i Controlling',
    'Konstrukcja i projektowanie',
    'Utrzymywanie ruchu',
    'Pozostali specjaliści logistyki',
    'Inżynieria technologiczna',
    'Pozostali specjaliści HR',
    'Zakupy i Zaopatrzenie',
    'Inżynieria jakości',
    'Grafika i animacja',
    'Mechatronika',
    'SEO/SEM',
    'Specjalista HR',
    'Doradztwo',
    'Copywriter',
    'Rozwój i szkolenia',
    'Backoffice',
    'Ubezpieczenia',
    'Łańcuch Dostaw',
    'Pozostali specjaliści marketingu',
    'Pozostali specjaliści finansów',
    'Planowanie produkcji',
    'Audyt i Compliance'
    )
) AS S
ON T.job_key = S.job_key

WHEN MATCHED THEN
  UPDATE SET
    T.ingested_at = S.ingested_at

WHEN NOT MATCHED THEN
  INSERT (
    job_key, ingested_at, source_name, category, title, company, city, seniority, workplace,
    contracts, tech_stack, original_url,
    must_have, responsibilities, offer_description
  )
  VALUES (
    S.job_key, S.ingested_at, S.source_name, S.category, S.title, S.company, S.city, S.seniority, S.workplace,
    S.contracts, S.tech_stack, S.original_url,
    S.must_have, S.responsibilities, S.offer_description
  );
