# Equivalence harness for check_policies.py. Renders the S3 Files policies for the three shapes
# whose conditionals differ: prefixed + SSE-KMS, whole-bucket, and two buckets with mixed KMS.
#
# Credentials are deliberately fake and every AWS lookup is skipped: aws_iam_policy_document is
# rendered locally, so this plans offline and must never be applied.

provider "aws" {
  region                      = "us-west-2"
  access_key                  = "harness"
  secret_key                  = "harness"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

locals {
  eks_info = {
    cluster = {
      specs = {
        name       = "example-cluster"
        account_id = "111122223333"
      }
    }
  }
  kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
}

# The common case: one prefixed, SSE-KMS bucket.
module "prefixed" {
  source = "../modules/pod-identity"

  region   = "us-west-2"
  eks_info = local.eks_info

  filetask_objectstore = {
    enabled = true
    buckets = [{
      name        = "example-bucket"
      prefix      = "datasets"
      kms_key_arn = local.kms_key_arn
    }]
  }
}

# No prefix and no KMS: the branch where the ListBucket condition must be absent entirely, because
# a StringLike on the absent s3:prefix key would deny every list rather than widen it.
module "whole_bucket" {
  source = "../modules/pod-identity"

  region   = "us-west-2"
  eks_info = local.eks_info

  filetask_objectstore = {
    enabled = true
    buckets = [{ name = "example-bucket" }]
  }
}

# Two buckets, only the second encrypted: proves each Sid index tracks its own bucket, and that
# filtering the unencrypted bucket out of the KMS list does not renumber the encrypted one.
module "two_buckets" {
  source = "../modules/pod-identity"

  region   = "us-west-2"
  eks_info = local.eks_info

  filetask_objectstore = {
    enabled = true
    buckets = [
      { name = "plain-bucket", prefix = "one" },
      { name = "kms-bucket", prefix = "two", kms_key_arn = local.kms_key_arn },
    ]
  }
}

# Disabled: nothing should be planned at all.
module "disabled" {
  source = "../modules/pod-identity"

  region   = "us-west-2"
  eks_info = local.eks_info
}
