# Regression test for the netapp node-access rules in node-group.tf.
#
# This class of bug is invisible to every other suite here. tests/plan runs a single root against
# no state, so both rules always plan as creates and nothing can go wrong; deploy-tests are fresh
# installs. Both bugs below were found on a live apply, one of them after Terraform had already
# destroyed the rule it was replacing.
#
#   Duplicate rule (fixed in 0d09cd6). The base rule used to key off the active-aware `netapp`
#   output, so once `active` named a replacement it targeted the same security group that
#   aws_security_group_rule.netapp_additional already opens, and AWS rejected the second with
#   InvalidPermission.Duplicate.
#
#   False destroy (fixed in b479c08). The base rule then keyed off `netapp_base` alone, so a
#   cluster plan reading an infra.tfstate written before that output existed saw count = 0 and
#   proposed deleting node access on every netapp deployment.
#
# Credential free by design: mock_provider only. Both rules derive their count and their
# security_group_id from input variables alone, so they are known at plan time and the mocks
# never have to return anything realistic.

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

# State written before netapp_base existed: only the legacy active-aware output is present.
# This is what a cluster dry run reads off disk on a deployment that has not had infra applied
# since this feature landed.
run "legacy_state_has_no_netapp_base" {
  command = plan

  variables {
    storage_info = {
      netapp = {
        svm = {
          name             = "test-deploy-svm"
          management_ip    = "10.0.0.1"
          nfs_ip           = "10.0.0.2"
          creds_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:test"
        }
        filesystem = { id = "fs-00000000000000001", security_group_id = "sg-base" }
        volume     = { name = "test_deploy_domino_shared_storage" }
      }
    }
  }

  assert {
    condition     = length(aws_security_group_rule.netapp) == 1
    error_message = "Node access to the base filesystem must survive a plan against state that predates netapp_base, not be proposed for deletion."
  }

  assert {
    condition     = aws_security_group_rule.netapp[0].security_group_id == "sg-base"
    error_message = "The base rule must target the base filesystem's security group."
  }

  assert {
    condition     = length(aws_security_group_rule.netapp_additional) == 0
    error_message = "State that predates netapp_base cannot have additional filesystems."
  }
}

# A netapp deployment that has never been resized.
run "no_additional_filesystem" {
  command = plan

  variables {
    storage_info = {
      netapp = {
        svm = {
          name             = "test-deploy-svm"
          management_ip    = "10.0.0.1"
          nfs_ip           = "10.0.0.2"
          creds_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:test"
        }
        filesystem = { id = "fs-00000000000000001", security_group_id = "sg-base" }
        volume     = { name = "test_deploy_domino_shared_storage" }
      }
      netapp_base       = { filesystem = { security_group_id = "sg-base" } }
      netapp_additional = {}
    }
  }

  assert {
    condition     = length(aws_security_group_rule.netapp) == 1
    error_message = "The base filesystem must have node access."
  }

  assert {
    condition     = aws_security_group_rule.netapp[0].security_group_id == "sg-base"
    error_message = "The base rule must target the base filesystem's security group."
  }

  assert {
    condition     = length(aws_security_group_rule.netapp_additional) == 0
    error_message = "No additional filesystem is declared, so no additional rule should exist."
  }
}

# Phase 1: a replacement exists, the base filesystem is still serving.
run "additional_declared_active_is_base" {
  command = plan

  variables {
    storage_info = {
      netapp = {
        svm = {
          name             = "test-deploy-svm"
          management_ip    = "10.0.0.1"
          nfs_ip           = "10.0.0.2"
          creds_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:test"
        }
        filesystem = { id = "fs-00000000000000001", security_group_id = "sg-base" }
        volume     = { name = "test_deploy_domino_shared_storage" }
      }
      netapp_base       = { filesystem = { security_group_id = "sg-base" } }
      netapp_additional = { "1" = { filesystem = { security_group_id = "sg-additional" } } }
    }
  }

  assert {
    condition     = aws_security_group_rule.netapp[0].security_group_id == "sg-base"
    error_message = "The base rule must target the base filesystem's security group."
  }

  assert {
    condition     = aws_security_group_rule.netapp_additional["1"].security_group_id == "sg-additional"
    error_message = "The additional rule must target the additional filesystem's security group."
  }
}

# Phase 3: cut over. `netapp` now resolves to the replacement, but the base filesystem still
# exists and must keep node access. This is the shape that produced InvalidPermission.Duplicate.
run "cut_over_keeps_the_two_rules_disjoint" {
  command = plan

  variables {
    storage_info = {
      netapp = {
        svm = {
          name             = "test-deploy-svm-1"
          management_ip    = "10.0.1.1"
          nfs_ip           = "10.0.1.2"
          creds_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:test-1"
        }
        filesystem = { id = "fs-00000000000000002", security_group_id = "sg-additional" }
        volume     = { name = "test_deploy_domino_shared_storage" }
      }
      netapp_base       = { filesystem = { security_group_id = "sg-base" } }
      netapp_additional = { "1" = { filesystem = { security_group_id = "sg-additional" } } }
    }
  }

  assert {
    condition     = length(aws_security_group_rule.netapp) == 1
    error_message = "The base filesystem still exists after a cutover and must keep node access."
  }

  assert {
    condition     = aws_security_group_rule.netapp[0].security_group_id == "sg-base"
    error_message = "The base rule must follow the base filesystem, not whichever one `active` selects."
  }

  assert {
    condition     = aws_security_group_rule.netapp[0].security_group_id != aws_security_group_rule.netapp_additional["1"].security_group_id
    error_message = "The two rules must never target the same security group: AWS rejects the second as a duplicate, after Terraform has destroyed the first."
  }
}

# Phase 4: retire_base. netapp_base is legitimately null here and `netapp` resolves to the
# replacement, so the legacy fallback must not fire.
run "retire_base_drops_the_base_rule" {
  command = plan

  variables {
    storage_info = {
      netapp = {
        svm = {
          name             = "test-deploy-svm-1"
          management_ip    = "10.0.1.1"
          nfs_ip           = "10.0.1.2"
          creds_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:test-1"
        }
        filesystem = { id = "fs-00000000000000002", security_group_id = "sg-additional" }
        volume     = { name = "test_deploy_domino_shared_storage" }
      }
      netapp_additional = { "1" = { filesystem = { security_group_id = "sg-additional" } } }
    }
  }

  assert {
    condition     = length(aws_security_group_rule.netapp) == 0
    error_message = "The base filesystem is destroyed by retire_base, so its rule must go with it rather than falling back onto the replacement's security group."
  }

  assert {
    condition     = length(aws_security_group_rule.netapp_additional) == 1
    error_message = "The replacement keeps its own rule after the base filesystem is retired."
  }
}

run "no_netapp_at_all" {
  command = plan

  variables {
    storage_info = {}
  }

  assert {
    condition     = length(aws_security_group_rule.netapp) == 0
    error_message = "A deployment without netapp must not get a netapp rule."
  }

  assert {
    condition     = length(aws_security_group_rule.netapp_additional) == 0
    error_message = "A deployment without netapp must not get an additional netapp rule."
  }
}
