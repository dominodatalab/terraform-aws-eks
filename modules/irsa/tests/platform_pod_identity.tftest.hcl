# Presets are rendered from templatefile(), which checkov and trivy cannot read, so the
# rendered documents are checked here. mock_provider only; every run is command = plan.

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

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

mock_provider "aws" {
  alias = "global"
}

variables {
  eks_info = {
    nodes = { roles = [] }
    cluster = {
      arn = "arn:aws:eks:us-east-1:123456789012:cluster/Test-Deploy"
      specs = {
        name       = "Test-Deploy"
        account_id = "123456789012"
      }
      oidc = {
        arn             = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
        id              = "EXAMPLE"
        url             = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
        thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
      }
    }
  }
}

run "disabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_eks_pod_identity_association.this) == 0 && length(aws_iam_role.this) == 0
    error_message = "platform_pod_identity must create nothing unless enabled."
  }
}

run "all_presets" {
  command = plan

  variables {
    platform_pod_identity = {
      enabled            = true
      kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
      buckets            = { backups = "test-backups", logs = "test-logs", blobs = "test-blobs" }
      efs_file_system_id = "fs-0123456789abcdef0"
      route53_zone_id    = "Z0123456789ABC"
    }
  }

  assert {
    condition = toset(keys(aws_eks_pod_identity_association.this)) == toset([
      "ebs-csi", "efs-csi", "cluster-autoscaler", "domino-admin-toolkit", "domino-data-importer",
      "fluentd", "mlflow", "nucleus", "nucleus-ecr-credential-refresher", "hephaestus", "external-dns",
    ])
    error_message = "Every preset must get a Pod Identity association."
  }

  assert {
    condition     = aws_eks_pod_identity_association.this["hephaestus"].namespace == "domino-compute" && aws_eks_pod_identity_association.this["hephaestus"].service_account == "hephaestus-buildkit"
    error_message = "hephaestus binds the hephaestus-buildkit service account in the compute namespace."
  }

  assert {
    condition     = aws_eks_pod_identity_association.this["nucleus"].namespace == "domino-platform" && aws_eks_pod_identity_association.this["cluster-autoscaler"].service_account == "cluster-autoscaler"
    error_message = "Platform presets bind service accounts in the platform namespace."
  }

  assert {
    condition     = aws_iam_role.this["nucleus"].name == "Test-Deploy-nucleus"
    error_message = "Role names are <cluster name>-<preset>."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.managed["ebs-csi|arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"].role == "Test-Deploy-ebs-csi" && !contains(keys(aws_iam_policy.this), "ebs-csi")
    error_message = "ebs-csi uses the AWS managed policy and no inline-style policy."
  }

  assert {
    condition     = length([for s in jsondecode(aws_iam_policy.this["fluentd"].policy).Statement : s if s.Sid == "ObjectReadWrite"][0].Resource) > 0 && [for s in jsondecode(aws_iam_policy.this["fluentd"].policy).Statement : s if s.Sid == "ObjectReadWrite"][0].Resource == "arn:aws:s3:::test-logs/*"
    error_message = "fluentd must be scoped to the logs bucket only."
  }

  assert {
    condition     = length(jsondecode(aws_iam_policy.this["nucleus"].policy).Statement) == 4 && length(jsondecode(aws_iam_policy.this["fluentd"].policy).Statement) == 3
    error_message = "Only nucleus carries the ECR token statement."
  }

  assert {
    condition     = contains(jsondecode(aws_iam_policy.this["hephaestus"].policy).Statement[1].Resource, "arn:aws:ecr:us-east-1:123456789012:repository/test-deploy/model")
    error_message = "ecr_repo_prefix defaults to the lower-cased cluster name."
  }

  assert {
    condition     = jsondecode(aws_iam_policy.this["domino-admin-toolkit"].policy).Statement[1].Resource == "arn:aws:eks:us-east-1:123456789012:cluster/Test-Deploy"
    error_message = "domino-admin-toolkit may describe only this cluster."
  }

  assert {
    condition     = jsondecode(aws_iam_policy.this["cluster-autoscaler"].policy).Statement[1].Condition.StringEquals["autoscaling:ResourceTag/k8s.io/cluster-autoscaler/Test-Deploy"] == "owned"
    error_message = "cluster-autoscaler may only scale groups tagged as owned by this cluster."
  }
}

run "skips_presets_without_inputs_and_honors_disabled" {
  command = plan

  variables {
    platform_pod_identity = {
      enabled         = true
      kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
      buckets         = { backups = "test-backups", logs = "test-logs", blobs = "test-blobs" }
      ecr_repo_prefix = "custom-prefix"
      disabled        = ["mlflow"]
    }
  }

  assert {
    condition     = !contains(keys(aws_eks_pod_identity_association.this), "efs-csi") && !contains(keys(aws_eks_pod_identity_association.this), "external-dns") && !contains(keys(aws_eks_pod_identity_association.this), "mlflow")
    error_message = "efs-csi (no file system), external-dns (no zone) and disabled presets must be skipped."
  }

  assert {
    condition     = contains(jsondecode(aws_iam_policy.this["hephaestus"].policy).Statement[1].Resource, "arn:aws:ecr:us-east-1:123456789012:repository/custom-prefix/environment")
    error_message = "ecr_repo_prefix must override the default."
  }
}

run "requires_kms_and_buckets" {
  command = plan

  variables {
    platform_pod_identity = {
      enabled = true
    }
  }

  expect_failures = [var.platform_pod_identity]
}

run "managed_policy_only_config_is_accepted" {
  command = plan

  variables {
    additional_irsa_configs = [{
      name                = "managed-only"
      namespace           = "ns"
      serviceaccount_name = "sa"
      pod_identity        = true
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }]
  }

  assert {
    condition     = !contains(keys(aws_iam_policy.this), "managed-only") && contains(keys(aws_iam_role.this), "managed-only")
    error_message = "A managed-policy-only entry creates a role but no aws_iam_policy."
  }
}
