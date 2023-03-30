data "aws_partition" "current" {}
data "aws_caller_identity" "aws_account" {}

locals {
  kubeconfig_path   = try(abspath(pathexpand(var.eks.kubeconfig.path)), "${path.cwd}/kubeconfig")
  kubeconfig        = merge(var.eks.kubeconfig, { path = local.kubeconfig_path })
  eks_cluster_name  = var.deploy_id
  aws_account_id    = data.aws_caller_identity.aws_account.account_id
  dns_suffix        = data.aws_partition.current.dns_suffix
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
  kms_key_arn       = try(var.kms_info.key_arn, null)
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

  node_security_group_rules = {
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
  }

  eks_info = {
    cluster = {
      public_access     = var.eks.public_access
      arn               = aws_eks_cluster.this.arn
      security_group_id = aws_security_group.eks_cluster.id
      endpoint          = aws_eks_cluster.this.endpoint
      roles = [{
        arn  = aws_iam_role.eks_cluster.arn
        name = aws_iam_role.eks_cluster.name
      }]
      custom_roles = var.eks.custom_role_maps
    }
    nodes = {
      security_group_id = aws_security_group.eks_nodes.id
      roles = [{
        arn  = aws_iam_role.eks_nodes.arn
        name = aws_iam_role.eks_nodes.name
      }]
    }
    kubeconfig = local.kubeconfig
  }
}
