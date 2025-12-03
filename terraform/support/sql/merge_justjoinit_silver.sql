MERGE INTO 
  `laborinsight-data.laborinsight.silver_justjoinit_jobs` AS T
USING (
    WITH LatestRawData AS (
        SELECT 
            payload,
            fingerprint AS job_key,
            ingested_at
        FROM 
            `laborinsight-data.laborinsight.bronze_justjoinit_jobs`
        WHERE 
            DATE(ingested_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
        AND source = 'justjoinit'
        QUALIFY ROW_NUMBER() OVER (PARTITION BY fingerprint ORDER BY ingested_at DESC) = 1
    )
    SELECT 
        t1.job_key,
        t1.ingested_at,
        'JustJoinIT' AS source_name,
        t_cat.category_name AS category,
        TRIM(JSON_VALUE(t1.payload, '$.title')) AS title,
        TRIM(REGEXP_REPLACE(JSON_VALUE(t1.payload, '$.companyName'), r'(?i)\s+(sp\.|spółka)\s+.*$', '')) AS company,
        COALESCE(TRIM(JSON_VALUE(t1.payload, '$.city')), 'Unknown') AS city,
        COALESCE(TRIM(JSON_VALUE(t1.payload, '$.experienceLevel')), 'Other') AS seniority,
        LOWER(JSON_VALUE(t1.payload, '$.workplaceType')) AS workplace,
        
        ARRAY(
             SELECT AS STRUCT
                LOWER(COALESCE(JSON_VALUE(c, '$.type'), 'undefined')) AS type,
                LOWER(JSON_VALUE(c, '$.unit')) AS unit,
                SAFE_CAST(JSON_VALUE(c, '$.from') AS NUMERIC) AS salary_min,
                SAFE_CAST(JSON_VALUE(c, '$.to') AS NUMERIC) AS salary_max,
                SAFE_CAST(JSON_VALUE(c, '$.gross') AS BOOLEAN) AS is_gross
            FROM UNNEST(JSON_QUERY_ARRAY(t1.payload, '$.employmentTypes')) AS c
        ) AS contracts,

        ARRAY(
            SELECT JSON_VALUE(skill) 
            FROM UNNEST(JSON_QUERY_ARRAY(t1.payload, '$.requiredSkills')) AS skill
        ) AS tech_stack,

        CONCAT('https://justjoin.it/job-offer/', JSON_VALUE(t1.payload, '$.slug')) AS original_url

    FROM LatestRawData AS t1
    LEFT JOIN `laborinsight-data.laborinsight.justjoinit_categories` t_cat
        ON SAFE_CAST(JSON_VALUE(t1.payload, '$.categoryId') AS INT64) = t_cat.category_id
    WHERE TRIM(JSON_VALUE(t1.payload, '$.title')) IS NOT NULL
) AS S
ON T.job_key = S.job_key

WHEN MATCHED THEN
  UPDATE SET T.ingested_at = S.ingested_at 

  WHEN NOT MATCHED THEN
  INSERT (
    job_key, ingested_at, source_name, category, title, company, city, seniority, workplace, 
    contracts, tech_stack, original_url
  )
  VALUES (
    S.job_key, S.ingested_at, S.source_name, S.category, S.title, S.company, S.city, S.seniority, S.workplace, 
    S.contracts, S.tech_stack, S.original_url
  );