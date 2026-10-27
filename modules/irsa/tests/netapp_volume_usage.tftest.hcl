# The role exists to read one ONTAP SVM secret. These runs pin the two properties that matter:
# the policy names only the ARNs it was given, and the trust is bound to one service account.
#
# mock_provider only; every run is command = plan.

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
      region = "us-west-2"
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
      arn = "arn:aws:eks:us-west-2:123456789012:cluster/test-deploy"
      specs = {
        name       = "test-deploy"
        account_id = "123456789012"
      }
      oidc = {
        arn             = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
        id              = "EXAMPLED539D4633E53DE1B716D3041E"
        url             = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
        thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
      }
    }
  }
}

run "policy_is_scoped_to_given_arns" {
  command = plan

  variables {
    netapp_volume_usage = {
      enabled             = true
      namespace           = "domino-compute"
      serviceaccount_name = "data-plane-agent"
      secret_arns         = ["arn:aws:secretsmanager:us-west-2:123456789012:secret:test-deploy-netapp-ontap-svm-AbCdEf"]
    }
  }

  assert {
    condition     = jsondecode(aws_iam_policy.netapp_volume_usage[0].policy).Statement[0].Resource == ["arn:aws:secretsmanager:us-west-2:123456789012:secret:test-deploy-netapp-ontap-svm-AbCdEf"]
    error_message = "The policy must name exactly the secret ARN it was given, with no wildcard."
  }

  assert {
    condition     = jsondecode(aws_iam_policy.netapp_volume_usage[0].policy).Statement[0].Action == ["secretsmanager:GetSecretValue"]
    error_message = "The policy must allow only secretsmanager:GetSecretValue."
  }

  assert {
    condition     = jsondecode(aws_iam_role.netapp_volume_usage[0].assume_role_policy).Statement[0].Condition.StringEquals["oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub"] == "system:serviceaccount:domino-compute:data-plane-agent"
    error_message = "The trust policy must condition :sub on the agent's service account."
  }

  assert {
    condition     = jsondecode(aws_iam_role.netapp_volume_usage[0].assume_role_policy).Statement[0].Condition.StringEquals["oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:aud"] == "sts.amazonaws.com"
    error_message = "The trust policy must condition :aud on sts.amazonaws.com."
  }
}

run "disabled_creates_nothing" {
  command = plan

  assert {
    condition     = length(aws_iam_role.netapp_volume_usage) == 0 && length(aws_iam_policy.netapp_volume_usage) == 0
    error_message = "Nothing may be created unless netapp_volume_usage.enabled is true."
  }
}

run "rejects_wildcard_arn" {
  command = plan

  variables {
    netapp_volume_usage = {
      enabled             = true
      namespace           = "domino-compute"
      serviceaccount_name = "data-plane-agent"
      secret_arns         = ["arn:aws:secretsmanager:us-west-2:123456789012:secret:test-deploy-netapp-ontap-*"]
    }
  }

  expect_failures = [var.netapp_volume_usage]
}

run "rejects_enabled_without_secret" {
  command = plan

  variables {
    netapp_volume_usage = {
      enabled             = true
      namespace           = "domino-compute"
      serviceaccount_name = "data-plane-agent"
    }
  }

  expect_failures = [var.netapp_volume_usage]
}
