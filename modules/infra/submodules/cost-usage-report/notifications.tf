# An Amazon S3 notification

resource "aws_s3_bucket_notification" "aws_put_s3_cur_notification" {
  bucket = aws_s3_bucket.cur_report.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.aws_cur_initializer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.s3_bucket_prefix}/"
    filter_suffix       = ".parquet"
  }

  depends_on = [
    aws_s3_bucket.cur_report,
    aws_lambda_permission.aws_s3_cur_event_lambda_permission,
    aws_s3_bucket_policy.cur_report,
  ]
}
