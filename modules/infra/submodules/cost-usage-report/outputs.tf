output "info" {
  description = <<EOF
    athena_info_configs = "Athena based cost reporting config information for kubecost cost-analyzer"
    athena_region"  = "athena region"
    athena_query_result_s3 = "S3 location for athena query results"
    cur_report_bucket_name = "Name of S3 bucket used for storing CUR data. This may be provisioned by this module or not."
    glue_catalog_database_name = "Name of the Glue Catalog Database which is populated with CUR data."
    glue_catalog_table_name = "Name of the Glue Catalog table which is populated with CUR data."
    s3_bucket_region  = "Region where the S3 bucket used for storing CUR data is provisioned. This may be provisioned by this module or not."
    report_name = "Name of the provisioned Cost and Usage Report."
  EOF
  value = {
    athena_info_configs = jsonencode(
      {
        "athenaRegion" : aws_cur_report_definition.aws_cur_report_definition[0].s3_region,
        "athenaDatabase" : aws_glue_catalog_database.aws_cur_database.name,
        "athenaTable" : aws_glue_catalog_table.aws_cur_report_status_table.name,
        "athenaBucketName" : aws_s3_bucket.athena_result[0].bucket,
        "projectID" : local.aws_account_id,
        "serviceKeyName" : "xxxx",
        "serviceKeySecret" : "xxxxxx"
      }
    )
    athena_query_result_s3     = aws_s3_bucket.athena_result[0].bucket
    athena_region              = aws_cur_report_definition.aws_cur_report_definition[0].s3_region
    cur_report_bucket_name     = aws_cur_report_definition.aws_cur_report_definition[0].s3_bucket
    glue_catalog_database_name = aws_glue_catalog_database.aws_cur_database.name
    glue_catalog_table_name    = aws_glue_catalog_table.aws_cur_report_status_table.name
    report_name                = aws_cur_report_definition.aws_cur_report_definition[0].report_name
    s3_bucket_region           = aws_cur_report_definition.aws_cur_report_definition[0].s3_region
  }
}
