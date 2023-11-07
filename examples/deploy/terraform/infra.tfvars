additional_node_groups = {}
bastion                = null
default_node_groups    = null
deploy_id              = null
eks = {
  cluster_addons     = null
  creation_role_name = null
  custom_role_maps   = null
  identity_providers = null
  k8s_version        = null
  kubeconfig = {
    extra_args = null
    path       = null
  }
  master_role_names = null
  nodes_master      = false
  public_access = {
    cidrs   = null
    enabled = null
  }
  ssm_log_group_name = null
  vpc_cni            = null
}
kms = null
network = {
  cidrs = {
    pod = "100.64.0.0/16"
    vpc = "10.0.0.0/16"
  }
  network_bits = {
    pod     = 19
    private = 19
    public  = 27
  }
  use_pod_cidr = true
  vpc = {
    id = null
    subnets = {
      pod     = []
      private = []
      public  = []
    }
  }
}
region                      = null
route53_hosted_zone_name    = null
route53_hosted_zone_private = false
ssh_pvt_key_path            = null
storage = {
  ecr = {
    force_destroy_on_deletion = true
  }
  efs = {
    access_point_path = "/domino"
    backup_vault = {
      backup = {
        cold_storage_after = 35
        delete_after       = 125
        schedule           = "0 12 * * ? *"
      }
      create        = true
      force_destroy = true
    }
  }
  s3 = {
    force_destroy_on_deletion = true
  }
}
tags = null

domino_cur = {
  provision_resources = null
  region = null
}