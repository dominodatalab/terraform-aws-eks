
data "archive_file" "cur_initializer_zip" {
  type        = "zip"
  output_path = "/tmp/aws_cur_initializer.zip"
  source {
    content = templatefile("${local.templates_dir}/${local.aws_cur_initializer_template}", {
      cur_crawler = local.cur_crawler
    })
    filename = local.index_filename
  }
  source {
    content = templatefile("${local.templates_dir}/${local.cfn_response_template}", {
      cur_crawler = local.cur_crawler
    })
    filename = local.cfn_response_filename
  }
}

resource "aws_lambda_function" "cur_lambda_initializer" {
  function_name = local.initializer_lambda_function
  role          = aws_iam_role.cur_lambda_initializer.arn

  filename         = data.archive_file.cur_initializer_zip.output_path
  source_code_hash = data.archive_file.cur_initializer_zip.output_base64sha256
  handler          = "index.handler"
  timeout          = 30
  runtime          = "nodejs16.x"

  reserved_concurrent_executions = 1
  kms_key_arn                    = local.kms_key_arn

  depends_on = [
    aws_glue_crawler.aws_cur_crawler
  ]
  environment {
    variables = {
      CRAWLER_NAME = aws_glue_crawler.aws_cur_crawler.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  # vpc_config {
  #   subnet_ids         = local.private_subnet_ids
  #   security_group_ids = [aws_security_group.lambda.id]
  # }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_csc.arn
}

resource "aws_security_group" "lambda" {
  name        = "${var.deploy_id}-lambda"
  description = "EFS security group"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.deploy_id}-lambda"
  }
}

resource "aws_lambda_permission" "aws_s3_cur_event_lambda_permission" {
  statement_id   = "AllowExecutionFromS3Bucket"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.cur_lambda_initializer.arn
  source_account = local.aws_account_id
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.cur_report.arn
}

data "archive_file" "aws_s3_cur_notification_zip" {
  type        = "zip"
  output_path = "/tmp/aws_s3_cur_notification.zip"
  source {
    content = templatefile("${local.templates_dir}/${local.aws_s3_cur_notification_template}", {
      cur_crawler = local.cur_crawler
    })
    filename = local.index_filename
  }
  source {
    content = templatefile("${local.templates_dir}/${local.cfn_response_template}", {
      cur_crawler = local.cur_crawler
    })
    filename = local.cfn_response_filename
  }
}

resource "aws_lambda_function" "aws_s3_cur_notification" {
  function_name = local.notification_lambda_function
  role          = aws_iam_role.aws_cur_lambda_executor.arn

  filename         = data.archive_file.aws_s3_cur_notification_zip.output_path
  source_code_hash = data.archive_file.aws_s3_cur_notification_zip.output_base64sha256
  handler          = "index.handler"
  timeout          = 30
  runtime          = "nodejs16.x"

  reserved_concurrent_executions = 1

  depends_on = [
    aws_lambda_function.cur_lambda_initializer,
    aws_lambda_permission.aws_s3_cur_event_lambda_permission,
  ]

  # vpc_config {
  #   subnet_ids         = local.private_subnet_ids
  #   security_group_ids = [aws_security_group.lambda.id]
  # }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_csc.arn
}

resource "aws_signer_signing_profile" "signing_profile" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "cur_sp_"
}

resource "aws_signer_signing_profile_permission" "sp_permission_start" {
  profile_name = aws_signer_signing_profile.signing_profile.name
  action       = "signer:StartSigningJob"
  principal    = local.aws_account_id
}

resource "aws_signer_signing_profile_permission" "sp_permission_get" {
  profile_name = aws_signer_signing_profile.signing_profile.name
  action       = "signer:GetSigningProfile"
  principal    = local.aws_account_id
}

resource "aws_lambda_code_signing_config" "lambda_csc" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.signing_profile.arn,
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }

  description = "Cost Usage Report Code signing configuration"
}

resource "aws_sqs_queue" "lambda_dlq" {
  kms_master_key_id = local.kms_key_arn
  name              = "${var.deploy_id}-terraform-lambda-queue"
}
