output "eks" {
  description = "Flyte eks info"
  value = {
    metadata_bucket       = aws_s3_bucket.flyte_metadata.bucket
    data_bucket           = aws_s3_bucket.flyte_data.bucket
    controlplane_role_arn = aws_iam_role.flyte_controlplane.arn
    dataplane_role_arn    = aws_iam_role.flyte_dataplane.arn
    gcp_token_audience    = "${local.deploy_id}-flyte-gcp-${random_id.server.hex}"
  }
}
