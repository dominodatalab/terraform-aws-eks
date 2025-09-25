deploy_id        = "plantest019"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

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
    "availability_zone_ids" = ["usw2-az1", "usw2-az2"]
  }
}


storage = {
  workspace_audit = {
    enabled                    = true
    events_bucket_name         = "workspace-events"
    events_archive_bucket_name = "workspace-events-archive"
  }
}
