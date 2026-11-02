# Tests for eks.api_ingress_cidrs: extra CIDRs allowed to reach the private EKS API on 443.
#
# Needed when the host running terraform/kubectl sits inside the VPC but is not in the nodes'
# security group and there is no bastion (air-gapped installs). The default of [] must leave
# the rule set exactly as it was: only the nodes-to-API rule.
#
# Credential free by design: mock_provider only. The rule map is built from input variables
# alone, so it is known at plan time.

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

# Default: nothing added, so existing deployments plan no new rules.
run "default_adds_no_cidr_rules" {
  command = plan

  assert {
    condition     = length(aws_security_group_rule.eks_cluster) == 1
    error_message = "With no api_ingress_cidrs only the nodes-to-API rule may exist."
  }

  assert {
    condition     = contains(keys(aws_security_group_rule.eks_cluster), "ingress_nodes_443")
    error_message = "The nodes-to-API rule must still exist."
  }
}

# Each CIDR becomes one 443 ingress rule on the cluster security group, alongside the nodes rule.
run "cidrs_add_api_ingress_rules" {
  command = plan

  variables {
    eks = {
      run_k8s_setup     = false
      api_ingress_cidrs = ["10.20.0.0/16", "100.65.0.0/16"]
    }
  }

  assert {
    condition     = length(aws_security_group_rule.eks_cluster) == 3
    error_message = "Expected the nodes rule plus one rule per CIDR."
  }

  assert {
    condition     = aws_security_group_rule.eks_cluster["ingress_api_10_20_0_0_16"].cidr_blocks == tolist(["10.20.0.0/16"])
    error_message = "The CIDR rule must allow exactly its own CIDR."
  }

  assert {
    condition     = aws_security_group_rule.eks_cluster["ingress_api_10_20_0_0_16"].from_port == 443 && aws_security_group_rule.eks_cluster["ingress_api_10_20_0_0_16"].to_port == 443 && aws_security_group_rule.eks_cluster["ingress_api_10_20_0_0_16"].type == "ingress"
    error_message = "The CIDR rule must be TCP 443 ingress."
  }

  assert {
    condition     = contains(keys(aws_security_group_rule.eks_cluster), "ingress_nodes_443")
    error_message = "Adding CIDRs must not remove the nodes-to-API rule."
  }
}

