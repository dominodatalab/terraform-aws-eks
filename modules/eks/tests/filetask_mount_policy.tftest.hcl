# Coverage for the node-role mount policy in filetask-mount-iam.tf.
#
# The policy is what lets the EFS CSI driver, which authenticates as the node, mount an S3 Files
# file system. A wider action list or a bare * resource silently widens every node in the cluster,
# so the exact action set and the resource shape are pinned here.
#
# mock_provider only. The document's `json` is mocked, so the assertions read the statement
# arguments off aws_iam_policy_document.filetask_mount, which are plain configuration.

# The generated mock values are random strings, which several attributes here reject outright:
# an IAM policy document's `json` has to parse, and an ARN has to look like one. Only the
# attributes that are validated or read downstream need a real shape.
mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_iam_session_context" {
    defaults = {
      issuer_arn  = "arn:aws:iam::123456789012:role/test-create-eks"
      issuer_name = "test-create-eks"
    }
  }
}

mock_provider "aws" {
  alias = "eks"

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
    }
  }

  mock_data "aws_iam_session_context" {
    defaults = {
      issuer_arn  = "arn:aws:iam::123456789012:role/test-create-eks"
      issuer_name = "test-create-eks"
    }
  }
}

mock_provider "tls" {}

variables {
  deploy_id           = "test-deploy"
  region              = "us-west-2"
  node_iam_policies   = []
  create_eks_role_arn = "arn:aws:iam::123456789012:role/test-create-eks"
  bastion_info        = null

  kms_info = {
    key_id  = "00000000-0000-0000-0000-000000000000"
    key_arn = "arn:aws:kms:us-west-2:123456789012:key/00000000-0000-0000-0000-000000000000"
    enabled = true
  }

  eks = {
    run_k8s_setup = false
  }

  ssh_key = {
    path          = "/dev/null"
    key_pair_name = "test-key"
  }

  network_info = {
    vpc_id = "vpc-00000000000000001"
    subnets = {
      public = [
        { name = "public-0", subnet_id = "subnet-00000000000000010", az = "us-west-2a", az_id = "usw2-az1" },
      ]
      private = [
        { name = "private-0", subnet_id = "subnet-00000000000000020", az = "us-west-2a", az_id = "usw2-az1" },
        { name = "private-1", subnet_id = "subnet-00000000000000021", az = "us-west-2b", az_id = "usw2-az2" },
      ]
      pod = []
    }
  }
}

run "mount_policy_exact_grant" {
  command = plan

  variables {
    filetask_objectstore_mount_enabled = true
  }

  assert {
    condition     = length(data.aws_iam_policy_document.filetask_mount[0].statement) == 1
    error_message = "The mount policy must have exactly one statement."
  }

  assert {
    condition     = [for s in data.aws_iam_policy_document.filetask_mount[0].statement : s.effect] == ["Allow"]
    error_message = "The mount statement must be an Allow."
  }

  assert {
    condition = toset(data.aws_iam_policy_document.filetask_mount[0].statement[0].actions) == toset([
      "s3files:ClientMount",
      "s3files:ClientWrite",
      "s3files:ClientRootAccess",
      "s3files:GetFileSystem",
    ])
    error_message = "The node role must be granted exactly s3files:ClientMount, ClientWrite, ClientRootAccess and GetFileSystem, and nothing else."
  }

  assert {
    condition     = length(data.aws_iam_policy_document.filetask_mount[0].statement[0].actions) == 4
    error_message = "The mount action list must hold four entries, with no duplicates hiding an extra action."
  }

  assert {
    condition     = try(length(data.aws_iam_policy_document.filetask_mount[0].statement[0].not_actions), 0) == 0 && try(length(data.aws_iam_policy_document.filetask_mount[0].statement[0].not_resources), 0) == 0
    error_message = "The mount statement may not use NotAction or NotResource: both grant everything except what they name."
  }

  assert {
    condition     = data.aws_iam_policy_document.filetask_mount[0].statement[0].resources == toset(["arn:aws:s3files:us-west-2:123456789012:file-system/*"])
    error_message = "The mount resource must be the file-system ARN pattern for this partition and account, not a bare * and not another account."
  }
}

run "mount_policy_disabled" {
  command = plan

  assert {
    condition     = length(data.aws_iam_policy_document.filetask_mount) == 0
    error_message = "The mount policy document must not be built when the mount is disabled."
  }

  assert {
    condition     = length(aws_iam_policy.filetask_mount) == 0
    error_message = "aws_iam_policy.filetask_mount must not be created when the mount is disabled."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.filetask_mount) == 0
    error_message = "aws_iam_role_policy_attachment.filetask_mount must not be created when the mount is disabled."
  }
}
