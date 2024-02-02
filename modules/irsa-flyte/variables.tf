variable "flyte" {
  description = <<EOF
    enabled = Whether to provision any Flyte related resources
    eks = {
      controlplane_role = Name of control plane role to create for Flyte
      dataplane_role = Name of data plane role to create for Flyte
    }
  EOF
  type = object({
    enabled = optional(bool, false)
    eks = optional(object({
      controlplane_role = optional(string, "flyte-controlplane-role")
      dataplane_role    = optional(string, "flyte-dataplane-role")
    }))
  })

  default = {}
}
