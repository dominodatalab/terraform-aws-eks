
data "archive_file" "aws_cur_initializer_zip" {
  type        = "zip"
  output_path = "/tmp/aws_cur_initializer.zip"
  source {
    content  = <<EOF
      const AWS = require('aws-sdk');
      const response = require('./cfn-response');
      exports.handler = function(event, context, callback) {
        if (event.RequestType === 'Delete') {
          response.send(event, context, response.SUCCESS);
        } else {
          const glue = new AWS.Glue();
          glue.startCrawler({ Name: 'AWSCURCrawler-domino-cur-crawler' }, function(err, data) {
            if (err) {
              const responseData = JSON.parse(this.httpResponse.body);
              if (responseData['__type'] == 'CrawlerRunningException') {
                callback(null, responseData.Message);
              } else {
                const responseString = JSON.stringify(responseData);
                if (event.ResponseURL) {
                  response.send(event, context, response.FAILED,{ msg: responseString });
                } else {
                  callback(responseString);
                }
              }
            }
            else {
              if (event.ResponseURL) {
                response.send(event, context, response.SUCCESS);
              } else {
                callback(null, response.SUCCESS);
              }
            }
          });
        }
      };
    EOF
    filename = "aws_cur_initializer.js"
  }
}

resource "aws_lambda_function" "aws_cur_initializer" {
  function_name = local.lambda_function_name
  role          = aws_iam_role.aws_cur_crawler_lambda_executor.arn

  filename         = data.archive_file.aws_cur_initializer_zip.output_path
  source_code_hash = data.archive_file.aws_cur_initializer_zip.output_base64sha256
  handler          = "index.handler"
  timeout          = 30
  runtime          = "nodejs16.x"

  reserved_concurrent_executions = 1
  kms_key_arn                    = local.kms_key_arn

  environment {
    variables = {
      CRAWLER_NAME = aws_glue_crawler.aws_cur_crawler.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [
    aws_iam_role_policy.aws_cur_crawler_lambda_executor,
    aws_glue_crawler.aws_cur_crawler
  ]

  dead_letter_config {
    target_arn = aws_s3_bucket.cur_report.arn
  }

  code_signing_config_arn = aws_signer_signing_profile.signing_profile.arn
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
  function_name  = aws_lambda_function.aws_cur_initializer.arn
  source_account = local.aws_account_id
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.cur_report.arn
}

data "archive_file" "aws_s3_cur_notification_zip" {
  type        = "zip"
  output_path = "/tmp/aws_s3_cur_notification.zip"
  source {
    content  = <<EOF
      const AWS = require('aws-sdk');
        const response = require('./cfn-response');
        exports.handler = function(event, context, callback) {
          const s3 = new AWS.S3();
          const putConfigRequest = function(notificationConfiguration) {
            return new Promise(function(resolve, reject) {
              s3.putBucketNotificationConfiguration({
                Bucket: event.ResourceProperties.BucketName,
                NotificationConfiguration: notificationConfiguration
              }, function(err, data) {
                if (err) reject({ msg: this.httpResponse.body.toString(), error: err, data: data });
                else resolve(data);
              });
            });
          };
          const newNotificationConfig = {};
          if (event.RequestType !== 'Delete') {
            newNotificationConfig.LambdaFunctionConfigurations = [{
              Events: [ 's3:ObjectCreated:*' ],
              LambdaFunctionArn: event.ResourceProperties.TargetLambdaArn || 'missing arn',
              Filter: { Key: { FilterRules: [ { Name: 'prefix', Value: event.ResourceProperties.ReportKey } ] } }
            }];
          }
          putConfigRequest(newNotificationConfig).then(function(result) {
            response.send(event, context, response.SUCCESS, result);
            callback(null, result);
          }).catch(function(error) {
            response.send(event, context, response.FAILED, error);
            console.log(error);
            callback(error);
          });
        };
      EOF
    filename = "aws_s3_cur_notification.js"
  }
}

resource "aws_lambda_function" "aws_s3_cur_notification" {
  function_name = "aws_s3_cur_notification-lambda"
  role          = aws_iam_role.aws_cur_lambda_executor.arn

  filename         = data.archive_file.aws_s3_cur_notification_zip.output_path
  source_code_hash = data.archive_file.aws_s3_cur_notification_zip.output_base64sha256
  handler          = "index.handler"
  timeout          = 30
  runtime          = "nodejs16.x"

  reserved_concurrent_executions = 1

  depends_on = [
    aws_lambda_function.aws_cur_initializer,
    aws_lambda_permission.aws_s3_cur_event_lambda_permission,
    aws_iam_role.aws_cur_lambda_executor
  ]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_s3_bucket.cur_report.arn
  }

  code_signing_config_arn = aws_signer_signing_profile.signing_profile.arn
}

resource "aws_signer_signing_profile" "signing_profile" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "domino_sp_"
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