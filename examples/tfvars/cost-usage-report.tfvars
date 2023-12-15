

deploy_id        = "jc-cur-1214-03"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

domino_cur = {
  provision_cost_usage_report = true
}

bastion = {
  enabled = true
}

default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}
additional_node_groups = {}

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


