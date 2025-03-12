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
    "availability_zone_ids" = ["usw2-az1", "usw2-az2"]
  }
}

vpn_connections = {
  create = true
  connections = [
    {
      name            = "customer-vpn-full"
      shared_ip       = "203.0.113.1"  # Replace with customer gateway IP
      cidr_blocks     = ["192.168.1.0/24", "192.168.2.0/24"]
      connection_type = "full"         # Connect to all subnets (default)
    },
    {
      name            = "customer-vpn-public"
      shared_ip       = "203.0.113.2"  # Replace with customer gateway IP
      cidr_blocks     = ["192.168.3.0/24", "192.168.4.0/24"]
      connection_type = "public_only"  # Connect to public subnets only
    }
  ]
}