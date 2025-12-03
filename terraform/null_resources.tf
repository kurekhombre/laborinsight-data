resource "null_resource" "seed_justjoinit_categories" {
  
  triggers = {
    sql_content_hash = filemd5("${path.module}/support/sql/lookup_table_categories_justjoinit.sql")
  }

  depends_on = [
    google_bigquery_table.justjoinit_categories 
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      bq query --use_legacy_sql=false \
               --project_id laborinsight-data \
               "$(cat ${path.module}/support/sql/lookup_table_categories_justjoinit.sql)"
    EOT
    
    when = create 
  }
}