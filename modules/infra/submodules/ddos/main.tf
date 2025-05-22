resource "aws_globalaccelerator_accelerator" "main_accelerator" {
  name            = "${var.deploy_id}-accelerator"
  enabled         = true
  ip_address_type = "IPV4"

  attributes {
    flow_logs_enabled   = var.flow_logs.enabled
    flow_logs_s3_bucket = var.flow_logs.s3_bucket
    flow_logs_s3_prefix = var.flow_logs.s3_prefix
  }
}