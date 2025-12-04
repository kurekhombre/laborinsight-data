

## README.md still in TODO :)

# LaborInsight -  IT Job Market Analysis Platform

## Project overview

LaborInsight  is a cloud-based system that collects, stores, and analyzes IT job offers from Polish IT recruitment sites.  
The main goal is to understand hiring trends using real job offers.

The platform uses Google Cloud Platform (GCP) and follows the Medallion Architecture (Bronze -> Silver -> Gold).  
All infrastructure is deployed automatically using Terraform.

The project involves:
- Cloud services
- Data pipelines
- Automation
- BigQuery data modeling
- CI/CD deployment

---

## Architecture & Data Flow

The system is event-driven and runs automatically:
1. **Schedule (Automation Layer)**
    Cloud Scheduler runs daily triggers for data collection and processing.
    In an ideal setup this orchestration layer would be implemented using Apache Airflow + Google Logging for better retries and monitoring. 

2. **Extract (API/Scraping)**  
   JustJoinIt offers a public API, so a Cloud Function is used to fetch data directly from their API instead of scraping.
   The rest of job portals do not offer an API, so they are scraped using Playwright (Python API) to download job offers from their websites.

3. **Publish (Cloud Function)**  
   A HTTP-triggered function sends raw job data to a Pub/Sub topic.

4. **Load (Cloud Function)**  
   A Pub/Sub-triggered function saves raw messages into BigQuery (Bronze layer).

5. **Transform (BigQuery)**  
   A scheduled process cleans, normalizes and deduplicates jobs (Silver layer),  
   then builds a views for reporting (Gold layer).

6. **Analyze (Dashboards)**  
   Looker Studio dashboards use Gold tables for reporting and insights.

---

## Repository Structure

| Folder / File | Description |
|---------------|-------------|
| `functions/` | Cloud Functions source code |
| └ `extract_justjoinit.py` | HTTP function — extract data (via API) and sends data to Pub/Sub |
| └ `load_jobs_raw.py` | Pub/Sub subscriber — loads raw data into BigQuery BRONZE LAYER |
| `web_scraping/` | WebScrapers 
| `terraform/` | IaC for GCP |
| └ `support/` | support files |
| └ `notebooks/` | Jupyter notebooks for scarpers - utilized by Colab Notebooks |
| └ `sql/` | SQL scripts: merge and lookup tables. |
---

TODO: SETUP~!