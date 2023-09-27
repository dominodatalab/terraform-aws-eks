single_node = {
  instance_type = "m5.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "dev-v2_sandbox_"
    owner       = "977170443939"

  }
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  },
}
