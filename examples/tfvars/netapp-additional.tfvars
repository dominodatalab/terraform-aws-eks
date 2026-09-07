deploy_id        = "plantest0015"
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

## Mid-flight resize-by-replacement: a smaller filesystem "1" has been provisioned alongside
## the base one and promoted, and the base one has not been retired yet. Setting
## retire_base = true is what decommissions the base filesystem once the replacement is proven.
storage = {
  filesystem_type = "netapp"
  netapp = {
    storage_capacity    = 1024
    throughput_capacity = 128
    additional = {
      "1" = {
        description         = "DOM-80370 resize destination"
        storage_capacity    = 512
        throughput_capacity = 128
        peering             = true
        storage_capacity_autosizing = {
          enabled = true
        }
      }
    }
    active      = "1"
    retire_base = false
  }
}
