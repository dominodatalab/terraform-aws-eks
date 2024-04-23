data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

data "aws_iam_role" "master_roles" {
  for_each = toset(var.eks.master_role_names)
  name     = each.key
}

data "aws_caller_identity" "aws_eks_provider" {
  provider = aws.eks
}

data "aws_iam_session_context" "create_eks_role" {
  provider = aws.eks
  arn      = data.aws_caller_identity.aws_eks_provider.arn
}

locals {
  kubeconfig_path             = var.eks.kubeconfig.path != null ? abspath(pathexpand(var.eks.kubeconfig.path)) : "${path.cwd}/kubeconfig"
  kubeconfig_args_list        = split(" ", chomp(trimspace(var.eks.kubeconfig.extra_args)))
  kubeconfig_args_list_parsed = contains(local.kubeconfig_args_list, "--role-arn") ? local.kubeconfig_args_list : concat(local.kubeconfig_args_list, ["--role-arn", data.aws_iam_session_context.create_eks_role.issuer_arn])
  kubeconfig_args             = join(" ", local.kubeconfig_args_list_parsed)
  kubeconfig = merge(var.eks.kubeconfig, {
    path       = local.kubeconfig_path
    extra_args = local.kubeconfig_args
  })
  eks_cluster_name  = var.deploy_id
  aws_account_id    = data.aws_caller_identity.aws_account.account_id
  dns_suffix        = data.aws_partition.current.dns_suffix
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
  kms_key_arn       = var.kms_info.key_arn
  eks_cluster_security_group_rules = {
    ingress_nodes_443 = {
      description              = "Private subnets to ${local.eks_cluster_name} EKS cluster API"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.eks_nodes.id
    }
  }

  node_security_group_rules = merge({
    egress_all = {
      description = "Allow all"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_cluster_15017 = {
      description                   = "Cluster API to node groups 15017, istio"
      protocol                      = "tcp"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_4443 = {
      description                   = "Cluster API to metrics-server APIService"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_5443 = {
      description                   = "Cluster API to calico APIService"
      protocol                      = "tcp"
      from_port                     = 5443
      to_port                       = 5443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_6443 = {
      description                   = "Cluster API to prometheus-adapter APIService"
      protocol                      = "tcp"
      from_port                     = 6443
      to_port                       = 6443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_9443 = {
      description                   = "Cluster API to Hephaestus webhook"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_8080 = {
      description                   = "Cluster API to Vault Agent webhook"
      protocol                      = "tcp"
      from_port                     = 8080
      to_port                       = 8080
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups 443"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_coredns_tcp = {
      description                   = "Cluster to node CoreDNS TCP"
      protocol                      = "tcp"
      from_port                     = 53
      to_port                       = 53
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_coredns_udp = {
      description                   = "Cluster to node CoreDNS UDP"
      protocol                      = "udp"
      from_port                     = 53
      to_port                       = 53
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_coredns_tcp = {
      description = "Node to node CoreDNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    ingress_self_coredns_udp = {
      description = "Node to node CoreDNS"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    inter_node_traffic_in_80 = {
      description = "Node to node http traffic"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      self        = true
    }
    inter_node_traffic_in_443 = {
      description = "Node to node https traffic"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      self        = true
    }
    inter_node_traffic_in = {
      description = "Node to node pod/svc trafic in"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    inter_node_traffic_out = {
      description = "Node to node pod/svc trafic out"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      type        = "egress"
      self        = true
    }
    ingress_cluster_8443 = {
      description                   = "Cluster API to NewRelic webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    }, var.privatelink.enabled ? {
    private_link = {
      description              = "NLB from private link to node ports"
      protocol                 = "tcp"
      from_port                = 30000
      to_port                  = 32767
      type                     = "ingress"
      source_security_group_id = module.privatelink[0].info.nlb_sg
    }
  } : {})


  eks_info = {
    cluster = {
      specs = {
        name                      = aws_eks_cluster.this.name
        endpoint                  = aws_eks_cluster.this.endpoint
        certificate_authority     = aws_eks_cluster.this.certificate_authority
        kubernetes_network_config = aws_eks_cluster.this.kubernetes_network_config
        account_id                = data.aws_caller_identity.cluster_aws_account.account_id
      }
      addons            = var.eks.cluster_addons
      vpc_cni           = var.eks.vpc_cni
      version           = aws_eks_cluster.this.version
      public_access     = var.eks.public_access
      arn               = aws_eks_cluster.this.arn
      security_group_id = aws_security_group.eks_cluster.id
      endpoint          = aws_eks_cluster.this.endpoint
      roles = concat(
        [
          for role in data.aws_iam_role.master_roles :
          {
            arn  = role.arn,
            name = role.id
          }
        ],
        [
          {
            arn  = aws_iam_role.eks_cluster.arn
            name = aws_iam_role.eks_cluster.name
          },
          {
            arn  = data.aws_iam_session_context.create_eks_role.issuer_arn
            name = data.aws_iam_session_context.create_eks_role.issuer_name
          }
        ]
      )
      custom_roles = var.eks.custom_role_maps
      oidc = {
        arn = aws_iam_openid_connect_provider.oidc_provider.arn
        url = aws_iam_openid_connect_provider.oidc_provider.url
        cert = {
          thumbprint_list = data.tls_certificate.cluster_tls_certificate.certificates[*].sha1_fingerprint
          url             = data.tls_certificate.cluster_tls_certificate.url

        }
      }
    }
    nodes = {
      nodes_master      = var.eks.nodes_master
      security_group_id = aws_security_group.eks_nodes.id
      roles = [{
        arn  = aws_iam_role.eks_nodes.arn
        name = aws_iam_role.eks_nodes.name
      }]
    }
    kubeconfig = local.kubeconfig
    calico     = var.calico
  }
}
