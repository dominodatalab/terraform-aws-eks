single_node = {
  instance_type = "m6i.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "dev-v2_"
    owner       = "977170443939"

  }
  eks = {
    k8s_version = "1.30"
  }
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  }
}
