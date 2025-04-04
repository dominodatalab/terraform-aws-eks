single_node = {
  instance_type = "m6i.2xlarge"
  name          = "dev-v2"
  ami = {
    name_prefix = "amazon-eks-node-al2023-x86_64-standard-"
    owner       = "602401143452"
  }
  labels = {
    "dominodatalab.com/node-pool"   = "default",
    "dominodatalab.com/domino-node" = "true"
  },
}

eks = {
  k8s_version = "1.28"
}
