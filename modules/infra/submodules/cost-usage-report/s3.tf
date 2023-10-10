
resource "aws_s3_bucket" "athena_result_bucket" {
  bucket = var.athena_cur_result_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "athena_result_bucket" {
  bucket = aws_s3_bucket.athena_result_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "cur_report_bucket" {
  bucket = var.cur_report_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "cur_report" {
  bucket = aws_s3_bucket.cur_report_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "s3_cur_report" {

  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]

    resources = [aws_s3_bucket.cur_report_bucket.arn]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.cur_report_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "cur_report" {

  bucket = aws_s3_bucket.cur_report_bucket.id
  policy = data.aws_iam_policy_document.s3_cur_report.json

  depends_on = [
    aws_s3_bucket_public_access_block.cur_report
  ]
}
