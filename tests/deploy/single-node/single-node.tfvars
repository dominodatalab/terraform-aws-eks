single_node = {
  instance_type = "m6i.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "dev-v2_"
    owner       = "977170443939"

  }
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  },
}
