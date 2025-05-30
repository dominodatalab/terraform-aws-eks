additional_node_groups = {}
bastion = {
  ami_id                   = null
  authorized_ssh_ip_ranges = null
  enabled                  = true
  install_binaries         = null
  instance_type            = null
  username                 = null
}
default_node_groups = null
deploy_id           = null
domino_cur = {
  provision_cost_usage_report = false
}
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
  oidc_provider = {
    create = true
    oidc   = null
  }
  public_access = {
    cidrs   = null
    enabled = null
  }
  run_k8s_setup      = null
  service_ipv4_cidr  = null
  ssm_log_group_name = null
  vpc_cni            = null
}
ignore_tags           = []
karpenter_node_groups = null
kms                   = null
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
region           = null
ssh_pvt_key_path = null
storage = {
  costs_enabled = false
  ecr = {
    create                    = true
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
  enable_remote_backup = false
  filesystem_type      = "efs"
  netapp = {
    automatic_backup_retention_days   = 90
    daily_automatic_backup_start_time = "00:00"
    deployment_type                   = "SINGLE_AZ_1"
    migrate_from_efs = {
      datasync = {
        enabled     = false
        schedule    = "cron(0 */4 * * ? *)"
        target      = "netapp"
        verify_mode = "ONLY_FILES_TRANSFERRED"
      }
      enabled = false
    }
    storage_capacity = 1024
    storage_capacity_autosizing = {
      enabled                    = false
      notification_email_address = ""
      percent_capacity_increase  = 30
      threshold                  = 70
    }
    throughput_capacity = 128
    volume = {
      create                     = true
      junction_path              = "/domino"
      name_suffix                = "domino_shared_storage"
      size_in_megabytes          = 1099511
      storage_efficiency_enabled = true
    }
  }
  s3 = {
    create                    = true
    force_destroy_on_deletion = true
  }
}
tags              = null
use_fips_endpoint = false
