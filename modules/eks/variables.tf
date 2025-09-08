variable "deploy_id" {
  type        = string
  description = "Domino Deployment ID"

  validation {
    condition     = can(regex("^[a-z-0-9]{3,32}$", var.deploy_id))
    error_message = "Argument deploy_id must: start with a letter, contain lowercase alphanumeric characters(can contain hyphens[-]) with length between 3 and 32 characters."
  }
}

variable "region" {
  type        = string
  description = "AWS region for the deployment"
  nullable    = false
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa|me|af|il)-(central|(north|south)?(east|west)?)-[0-9]", var.region))
    error_message = "The provided region must follow the format of AWS region names, e.g., us-west-2, us-gov-west-1."
  }
}

variable "network_info" {
  description = <<EOF
    id = VPC ID.
    ecr_endpoint = {
      security_group_id = ECR Endpoint security group id.
    }
    s3_endpoint = {
      security_group_id = S3 Endpoint security group id.
    }
    subnets = {
      public = List of public Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      private = List of private Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
      pod = List of pod Subnets.
      [{
        name = Subnet name.
        subnet_id = Subnet ud
        az = Subnet availability_zone
        az_id = Subnet availability_zone_id
      }]
    }
  EOF
  type = object({
    vpc_id = string
    ecr_endpoint = optional(object({
      security_group_id = optional(string, null)
    }), null)
    s3_endpoint = optional(object({
      security_group_id = optional(string, null)
    }), null)
    subnets = object({
      public = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      private = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
      pod = list(object({
        name      = string
        subnet_id = string
        az        = string
        az_id     = string
      }))
    })
    vpc_cidrs = optional(string, "10.0.0.0/16")
  })

  validation {
    condition     = length(var.network_info.subnets.private) >= 2
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
  validation {
    condition     = length(var.network_info.subnets.pod) != 1
    error_message = "EKS deployment needs at least 2 subnets. https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  }
}

variable "node_iam_policies" {
  description = "Additional IAM Policy Arns for Nodes"
  type        = list(string)
}

variable "bastion_info" {
  description = <<EOF
    user                = Bastion username.
    public_ip           = Bastion public ip.
    security_group_id   = Bastion sg id.
    ssh_bastion_command = Command to ssh onto bastion.
  EOF
  type = object({
    user                = string
    public_ip           = string
    security_group_id   = string
    ssh_bastion_command = string
  })
}

variable "kms_info" {
  description = <<EOF
    key_id  = KMS key id.
    key_arn = KMS key arn.
    enabled = KMS key is enabled
    key_policy_arn = KMS Policy ARN when key is provided
    provided_key = If KMS Key was provided
  EOF
  type = object({
    key_id         = optional(string, null)
    key_arn        = optional(string, null)
    enabled        = optional(bool, true)
    key_policy_arn = optional(string, null)
    provided_key   = optional(bool, false)
  })
}

variable "eks" {
  description = <<EOF
    run_k8s_setup = Toggle to run the k8s setup.
    service_ipv4_cidr = CIDR for EKS cluster kubernetes_network_config.
    creation_role_name = Name of the role to import.
    k8s_version = EKS cluster k8s version.
    nodes_master  Grants the nodes role system:master access. NOT recomended
    kubeconfig = {
      extra_args = Optional extra args when generating kubeconfig.
      path       = Fully qualified path name to write the kubeconfig file.
    }
    public_access = {
      enabled = Enable EKS API public endpoint.
      cidrs   = List of CIDR ranges permitted for accessing the EKS public endpoint.
    }
    Custom role maps for aws auth configmap
    custom_role_maps = {
      rolearn = string
      username = string
      groups = list(string)
    }
    master_role_names = IAM role names to be added as masters in eks.
    cluster_addons = EKS cluster addons. vpc-cni is installed separately.
    vpc_cni = Configuration for AWS VPC CNI
    ssm_log_group_name = CloudWatch log group to send the SSM session logs to.
    identity_providers = Configuration for IDP(Identity Provider).
    create_oidc_provider = Toggle to create the IAM OIDC Identity Provider.
    oidc_provider = Configuration for the IAM OIDC Identity Provider.
  }
  EOF

  type = object({
    run_k8s_setup      = optional(bool, true)
    service_ipv4_cidr  = optional(string, "172.20.0.0/16")
    creation_role_name = optional(string, null)
    k8s_version        = optional(string, "1.30")
    nodes_master       = optional(bool, false)
    kubeconfig = optional(object({
      extra_args = optional(string, "")
      path       = optional(string, null)
    }), {})
    public_access = optional(object({
      enabled = optional(bool, false)
      cidrs   = optional(list(string), [])
    }), {})
    custom_role_maps = optional(list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    })), [])
    master_role_names  = optional(list(string), [])
    cluster_addons     = optional(list(string), ["kube-proxy", "coredns", "vpc-cni", "eks-pod-identity-agent"])
    ssm_log_group_name = optional(string, "session-manager")
    vpc_cni = optional(object({
      prefix_delegation = optional(bool, false)
      annotate_pod_ip   = optional(bool, true)
    }))
    identity_providers = optional(list(object({
      client_id                     = string
      groups_claim                  = optional(string, null)
      groups_prefix                 = optional(string, null)
      identity_provider_config_name = string
      issuer_url                    = optional(string, null)
      required_claims               = optional(map(string), null)
      username_claim                = optional(string, null)
      username_prefix               = optional(string, null)
    })), []),
    oidc_provider = optional(object({
      create = optional(bool, true)
      oidc = optional(object({
        id              = optional(string, null)
        arn             = optional(string, null)
        url             = optional(string, null)
        thumbprint_list = optional(list(string), null)
      }), null)
    }), {})
  })

  default = {}
}

variable "ssh_key" {
  description = <<EOF
    path          = SSH private key filepath.
    key_pair_name = AWS key_pair name.
  EOF
  type = object({
    path          = string
    key_pair_name = string
  })
}

variable "create_eks_role_arn" {
  description = "Role arn to assume during the EKS cluster creation."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Deployment tags."
  default     = {}
}

variable "ignore_tags" {
  type        = list(string)
  description = "Tag keys to be ignored by the aws provider."
  default     = []
}

variable "use_fips_endpoint" {
  description = "Use aws FIPS endpoints"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_namespace" {
  description = "Controller Namespace"
  type        = string
  default     = "domino-platform"
}

variable "calico" {
  description = <<EOF
    calico = {
      version = Configure the version for Calico
      image_registry = Configure the image registry for Calico
      node_selector = Configure the node selector for Calico control plane components
    }
  EOF

  type = object({
    image_registry = optional(string, "quay.io")
    version        = optional(string, "v3.28.2")
    node_selector = optional(object({
      key   = optional(string, "dominodatalab.com/calico-controlplane")
      value = optional(string, "true")
    }), {})
  })
  default = {}
}

variable "storage_info" {
  description = "Defines the configuration for different storage types like EFS, S3, and ECR."

  type = object({
    efs = optional(object({
      security_group_id = optional(string, null)
    }), null)
    netapp = optional(object({
      svm = object({
        name             = optional(string, null)
        management_ip    = optional(string, null)
        nfs_ip           = optional(string, null)
        creds_secret_arn = optional(string, null)
      })
      filesystem = object({
        id                = optional(string, null)
        security_group_id = optional(string, null)
      })
      volume = object({
        name = optional(string, null)
      })
    }), null)
  })

  default = {}
}

variable "karpenter" {
  description = <<EOF
    karpenter = {
      enabled = Toggle installation of Karpenter.
      namespace = Namespace to install Karpenter.
      version = Configure the version for Karpenter.
      delete_instances_on_destroy = Toggle to delete Karpenter instances on destroy.
      vm_memory_overhead_percent  = Configure the vm memory overhead percent for Karpenter, represented in decimal form (%/100), i.e 7.5% = 0.075.
    }
  EOF
  type = object({
    enabled                     = optional(bool, false)
    delete_instances_on_destroy = optional(bool, false)
    namespace                   = optional(string, "karpenter")
    version                     = optional(string, "1.6.3")
    vm_memory_overhead_percent  = optional(string, "0.075")
    #https://karpenter.sh/docs/upgrading/compatibility/#compatibility-matrix
    #https://github.com/aws/karpenter-provider-aws/releases
  })

  validation {
    condition     = var.karpenter.vm_memory_overhead_percent != null && tonumber(var.karpenter.vm_memory_overhead_percent) >= 0 && tonumber(var.karpenter.vm_memory_overhead_percent) <= 0.1
    error_message = "Karpenter vm_memory_overhead_percent represented in decimal form (%/100, i.e 7.5% = 0.075), must be between 0 and 0.1 (0-10%)"
  }

  default = {}
}
