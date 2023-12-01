# three IAM roles

data "aws_iam_policy_document" "cur_crawler_component_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "aws_cur_crawler_component_function_role" {
  name_prefix        = "crawler_component_function_role"
  assume_role_policy = data.aws_iam_policy_document.cur_crawler_component_assume_role_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "aws_cur_crawler_component_function_policy" {

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }

  statement {
    sid = "Glue"

    effect = "Allow"

    actions = [
      "glue:ImportCatalogToGlue",
      "glue:GetDatabase",
      "glue:UpdateDatabase",
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:BatchGetPartition",
      "glue:UpdatePartition",
      "glue:BatchCreatePartition",
      "glue:GetSecurityConfiguration",
    ]

    resources = ["*"]
  }

  statement {
    sid = "S3"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutBucket",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}/${var.cost_usage_report.s3_bucket_prefix}/dominoCost/dominoCost*",
    ]
  }

  statement {
    sid = "S3Decrypt"

    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "aws_cur_crawler_component_function_policy" {
  role   = aws_iam_role.aws_cur_crawler_component_function_role.name
  policy = data.aws_iam_policy_document.aws_cur_crawler_component_function_policy.json
}


data "aws_iam_policy_document" "cur_lambda_initializer_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cur_lambda_initializer" {
  name               = "${var.deploy_id}-${var.cost_usage_report.report_name}-crawler-lambda-initializer"
  assume_role_policy = data.aws_iam_policy_document.cur_lambda_initializer_assume.json
}

data "aws_iam_policy_document" "cur_lambda_initializer_pd" {

  statement {
    sid = "CreateNetworkInterface"

    effect = "Allow"

    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]

    resources = ["*"]
  }

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }

  statement {
    sid = "SQS"

    effect = "Allow"

    actions = [
      "sqs:*",
    ]

    resources = [
      aws_sqs_queue.lambda_dlq.arn
    ]
  }

  statement {
    sid = "Glue"

    effect = "Allow"

    actions = [
      "glue:StartCrawler",
    ]

    resources = [aws_glue_crawler.aws_cur_crawler.arn]
  }
}

resource "aws_iam_policy" "cur_lambda_initializer_p" {
  name   = "${var.deploy_id}-${var.cost_usage_report.report_name}-cur-lambda-initializer"
  policy = data.aws_iam_policy_document.cur_lambda_initializer_pd.json
}

resource "aws_iam_role_policy_attachment" "cur_lambda_initializer_rp" {
  role       = aws_iam_role.cur_lambda_initializer.name
  policy_arn = aws_iam_policy.cur_lambda_initializer_p.arn
}


data "aws_iam_policy_document" "aws_cur_lambda_executor_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "aws_cur_lambda_executor" {
  name               = "${var.deploy_id}-${var.cost_usage_report.report_name}-lambda-executor"
  assume_role_policy = data.aws_iam_policy_document.aws_cur_lambda_executor_assume.json
}

data "aws_iam_policy_document" "aws_cur_lambda_executor" {

  statement {
    sid = "CreateNetworkInterface"

    effect = "Allow"

    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]

    resources = ["*"]
  }


  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }

  statement {
    sid = "SQS"

    effect = "Allow"

    actions = [
      "sqs:*",
    ]

    resources = [
      aws_sqs_queue.lambda_dlq.arn
    ]
  }

  statement {
    sid = "Glue"

    effect = "Allow"

    actions = [
      "s3:PutBucketNotification"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}"
    ]
  }
}

resource "aws_iam_policy" "aws_cur_lambda_executor_p" {
  name   = "${var.deploy_id}-${var.cost_usage_report.report_name}-cur-lambda-executor"
  policy = data.aws_iam_policy_document.aws_cur_lambda_executor.json
}

resource "aws_iam_role_policy_attachment" "aws_cur_lambda_executor_rpa" {
  role       = aws_iam_role.aws_cur_lambda_executor.name
  policy_arn = aws_iam_policy.aws_cur_lambda_executor_p.arn
}
