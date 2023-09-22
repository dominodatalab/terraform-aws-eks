default_node_groups    = null
additional_node_groups = null
single_node = {
  create = true
  instance_types = [
    "m5.2xlarge"
  ],
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  },
}
