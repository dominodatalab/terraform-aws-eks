single_node = {
  instance_type = "m6i.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "amazon-eks-node-al2023-x86_64-standard-"
  }
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  },
}

eks = {
  k8s_version = "1.30"
}
