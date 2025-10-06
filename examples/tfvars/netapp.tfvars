deploy_id        = "plantest0014"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
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

storage = {
  filesystem_type = "netapp"
  netapp = {
    migrate_from_efs = {
      enabled = true
    }
    storage_capacity_autosizing = {
      enabled = true
    }
  }

}
