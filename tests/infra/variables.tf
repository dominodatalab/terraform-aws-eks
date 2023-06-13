variable "deploy_id" {
  description = "Domino Deployment ID."
  type        = string
}

variable "region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "tags" {
  description = "Deployment tags."
  type        = map(string)
}

variable "k8s_version" {
  description = "EKS cluster k8s version."
  type        = string
}

variable "default_node_groups" {
  description = "EKS managed node groups definition."
}
variable "additional_node_groups" {
  description = "Additional EKS managed node groups definition."

}
variable "kms" {
  description = <<EOF
    enabled = Toggle,if set use either the specified KMS key_id or a Domino-generated one.
    key_id  = optional(string, null)
  EOF
}
variable "eks" {
  description = <<EOF
    k8s_version = EKS cluster k8s version.
    kubeconfig = {
      extra_args = Optional extra args when generating kubeconfig.
      path       = Fully qualified path name to write the kubeconfig file.
    }
    public_access = {
      enabled = Enable EKS API public endpoint.
      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.
    }
    "Custom role maps for aws auth configmap
    custom_role_maps = {
      rolearn  = string
      username = string
      groups   = list(string)
    }
    master_role_names  = IAM role names to be added as masters in eks.
    cluster_addons     = EKS cluster addons. vpc-cni is installed separately.
    vpc_cni            = Configuration for AWS VPC CNI
    ssm_log_group_name = CloudWatch log group to send the SSM session logs to.
    identity_providers = Configuration for IDP(Identity Provider).
  }
  EOF

}
variable "ssh_pvt_key_path" {
  type        = string
  description = "SSH private key filepath."
}
variable "route53_hosted_zone_name" {
  type        = string
  description = "Optional hosted zone for External DNS zone."
}
variable "bastion" {
  type        = map(any)
  description = <<EOF
    enabled                  = Create bastion host.
    ami                      = Ami id. Defaults to latest 'amazon_linux_2' ami.
    instance_type            = Instance type.
    authorized_ssh_ip_ranges = List of CIDR ranges permitted for the bastion ssh access.
    username                 = Bastion user.
    install_binaries         = Toggle to install required Domino binaries in the bastion.
  EOF
}
