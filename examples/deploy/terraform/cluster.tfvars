eks = {
  k8s_version = "1.27"
  public_access = {
    enabled = true
    cidrs   = ["0.0.0.0/0"]
  }
}

kms_info = null
