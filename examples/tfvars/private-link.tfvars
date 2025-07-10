deploy_id        = "plantest009"
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

## bastion is enabled by default
bastion = {
  enabled = true
}

enable_private_link = true

load_balancers = [{
  name            = "vault"
  type            = "network"
  internal        = true
  ddos_protection = false
  listeners = [
    {
      name     = "tls"
      port     = 8200
      protocol = "TCP"
    }
  ]
  }, {
  name            = "rabbitmq"
  type            = "network"
  internal        = true
  ddos_protection = false
  listeners = [
    {
      name     = "tls"
      port     = 5552
      protocol = "TCP"
    },
    {
      name     = "stream-tls"
      port     = 5672
      protocol = "TCP"
    }
  ]
}]
