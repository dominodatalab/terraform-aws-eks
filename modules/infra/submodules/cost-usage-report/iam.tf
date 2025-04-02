# three IAM roles

data "aws_iam_policy_document" "cur_crawler_component_assume_role_policy" {

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy" "aws_glue_service_role" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role" "aws_cur_crawler_component_function_role" {
  name_prefix        = substr("${var.deploy_id}-crawler_comp_func_role", 0, 37)
  assume_role_policy = data.aws_iam_policy_document.cur_crawler_component_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cur_crawler_glue_service_role_policy_attach" {
  role       = aws_iam_role.aws_cur_crawler_component_function_role.name
  policy_arn = data.aws_iam_policy.aws_glue_service_role.arn
}

data "aws_iam_policy_document" "aws_cur_crawler_component_function_policy" {

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey",
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
      "glue:StartCrawler"
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
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}/${var.cost_usage_report.s3_bucket_prefix}/*",
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
      "s3:PutBucketNotification",
      "glue:StartCrawler",
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

resource "aws_vpc_endpoint_policy" "aws_cur_crawler_endpoint_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.aws_glue_vpc_endpoint.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "glue:StartCrawler"
        ],
        "Resource" : "*"
      }
    ]
  })

}

data "aws_iam_policy_document" "query_cost_usage_report" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:ListQueryExecutions",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:ListWorkGroups",
      "athena:ListEngineVersions",
      "athena:GetWorkGroup",
      "athena:GetDataCatalog",
      "athena:GetDatabase",
      "athena:GetTableMetadata",
      "athena:ListDataCatalogs",
      "athena:ListDatabases",
      "athena:ListTableMetadata"
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.athena_result.bucket}",
    ]

    actions = [
      "s3:ListBucketMultipartUploads",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cur_report.bucket}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.athena_result.bucket}/*",
    ]

    actions = [
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload"
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:glue:*:*:catalog",
      "arn:${data.aws_partition.current.partition}:glue:*:*:database/${var.deploy_id}-athena-cur-cost-db*",
      "arn:${data.aws_partition.current.partition}:glue:*:*:table/${var.deploy_id}*/*",
    ]

    actions = [
      "glue:GetDatabase*",
      "glue:GetTable*",
      "glue:GetPartition*",
      "glue:GetUserDefinedFunction",
      "glue:BatchGetPartition"
    ]
  }
}

resource "aws_iam_policy" "query_cost_usage_report" {
  name   = "${var.deploy_id}-query_cost_usage_report"
  path   = "/"
  policy = data.aws_iam_policy_document.query_cost_usage_report.json
}
