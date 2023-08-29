data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

locals {
  aws_account_id = data.aws_caller_identity.aws_account.account_id
}