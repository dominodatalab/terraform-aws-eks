# An AWS Glue database
# An AWS Glue crawler
# Two Lambda functions

resource "aws_glue_catalog_database" "aws_cur_database" { # done
  description = "Contains CUR data based on contents from the S3 bucket '${var.cur_report_bucket_name}'"
  name        = "${var.aws_glue_database}-db"
  catalog_id  = local.aws_account_id
}

resource "aws_glue_crawler" "aws_cur_crawler" {
  name          = "AWSCURCrawler-domino-cur-crawler"
  description   = "A recurring crawler that keeps your CUR table in Athena up-to-date."
  database_name = aws_glue_catalog_database.aws_cur_database.name
  role          = aws_iam_role.aws_cur_crawler_component_function_role.name

  s3_target {
    path = "s3://${var.cur_report_bucket_name}/${var.s3_bucket_prefix}/${var.cur_report_name}/${var.cur_report_name}"
    exclusions = [
      "**.json",
      "**.yml",
      "**.sql",
      "**.csv",
      "**.gz",
      "**.zip",
    ]
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = var.tags

  depends_on = [
    aws_glue_catalog_database.aws_cur_database,
    aws_iam_role.aws_cur_crawler_component_function_role,
    aws_s3_bucket.cur_report
  ]
}

resource "aws_glue_catalog_table" "aws_cur_report_status_table" {
  name          = local.report_status_table_name
  database_name = aws_glue_catalog_database.aws_cur_database.name
  table_type    = "EXTERNAL_TABLE"
  catalog_id    = local.aws_account_id

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${var.cur_report_bucket_name}/${var.s3_bucket_prefix}/${var.cur_report_name}/${local.report_status_table_name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "glue_serde_info"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "status"
      type = "string"
    }

  }

  depends_on = [
    aws_glue_catalog_database.aws_cur_database
  ]

}

resource "aws_athena_workgroup" "athena_work_group" {
  name = "athena_work_group"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_result.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = local.kms_key_arn
      }
    }
  }
}
