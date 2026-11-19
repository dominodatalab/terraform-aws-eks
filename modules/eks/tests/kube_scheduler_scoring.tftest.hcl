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
    oidc_provider = { create = false }
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

run "karpenter_defaults_to_most_allocated" {
  command = plan

  variables {
    karpenter = { enabled = true }
  }

  assert {
    condition     = aws_eks_cluster.this.kube_scheduler_config[0].node_resources_fit[0].scoring_strategy[0].type == "MostAllocated"
    error_message = "Karpenter clusters must default to MostAllocated."
  }

  assert {
    condition = {
      for resource in aws_eks_cluster.this.kube_scheduler_config[0].node_resources_fit[0].scoring_strategy[0].resource :
      resource.name => resource.weight
    } == { cpu = 1, memory = 1 }
    error_message = "The scheduler must score CPU and memory with equal weights of 1."
  }
}

run "no_karpenter_leaves_scheduler_unset" {
  command = plan

  assert {
    condition     = length(aws_eks_cluster.this.kube_scheduler_config) == 0
    error_message = "A cluster without Karpenter or a scoring override must omit the scheduler configuration."
  }
}

run "karpenter_accepts_least_allocated_override" {
  command = plan

  variables {
    karpenter = { enabled = true }
    eks = {
      run_k8s_setup                   = false
      oidc_provider                   = { create = false }
      kube_scheduler_scoring_strategy = "LeastAllocated"
    }
  }

  assert {
    condition     = aws_eks_cluster.this.kube_scheduler_config[0].node_resources_fit[0].scoring_strategy[0].type == "LeastAllocated"
    error_message = "An explicit LeastAllocated strategy must override the Karpenter default."
  }
}

run "no_karpenter_accepts_most_allocated_override" {
  command = plan

  variables {
    eks = {
      run_k8s_setup                   = false
      oidc_provider                   = { create = false }
      kube_scheduler_scoring_strategy = "MostAllocated"
    }
  }

  assert {
    condition     = aws_eks_cluster.this.kube_scheduler_config[0].node_resources_fit[0].scoring_strategy[0].type == "MostAllocated"
    error_message = "MostAllocated must be configurable without Karpenter."
  }
}

run "rejects_unsupported_strategy" {
  command = plan

  variables {
    eks = {
      run_k8s_setup                   = false
      oidc_provider                   = { create = false }
      kube_scheduler_scoring_strategy = "RequestedToCapacityRatio"
    }
  }

  expect_failures = [var.eks]
}
