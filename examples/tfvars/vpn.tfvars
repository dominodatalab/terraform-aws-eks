deploy_id        = "plantest0013"
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

vpn_connections = {
  create = true
  connections = [
    {
      name        = "vpn_connection_test_1"
      shared_ip   = "203.0.113.12"
      cidr_blocks = ["192.168.0.0/16"]
    },
    {
      name        = "vpn_connection_test_2"
      shared_ip   = "200.0.110.120"
      cidr_blocks = ["3.4.5.6/16"]
    }
  ]
}
