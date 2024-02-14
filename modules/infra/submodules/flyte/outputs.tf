output "flyte" {
  description = "Flyte info"
  value = {
    eks = {
      account_id            = local.aws_account_id
      controlplane_role_arn = aws_iam_role.flyte_controlplane.arn
      dataplane_role_arn    = aws_iam_role.flyte_dataplane.arn
    }
  }
}
