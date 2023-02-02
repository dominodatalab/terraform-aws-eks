data "aws_partition" "current" {}

locals {
  eks_cluster_name  = var.deploy_id
  dns_suffix        = data.aws_partition.current.dns_suffix
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
  eks_cluster_security_group_rules = {
    ingress_nodes_443 = {
      description              = "Private subnets to ${local.eks_cluster_name} EKS cluster API"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.eks_nodes.id
    }
    egress_nodes_9443 = {
      description              = "EKS control plane to nodes"
      protocol                 = "tcp"
      from_port                = 9443
      to_port                  = 9443
      type                     = "egress"
      source_security_group_id = aws_security_group.eks_nodes.id
    }
    egress_nodes_443 = {
      description              = "${local.eks_cluster_name} EKS cluster API to private subnets"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "egress"
      source_security_group_id = aws_security_group.eks_nodes.id
    }
    egress_nodes_kubelet = {
      description              = "${local.eks_cluster_name} EKS cluster API to private subnets"
      protocol                 = "tcp"
      from_port                = 10250
      to_port                  = 10250
      type                     = "egress"
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
    ingress_cluster_9443 = {
      description                   = "Cluster API to node groups 9443, hephaestus"
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
      from_port   = 1025
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    inter_node_traffic_out = {
      description = "Node to node pod/svc trafic out"
      protocol    = "tcp"
      from_port   = 1025
      to_port     = 65535
      type        = "egress"
      self        = true
    }
  }

  bastion_eks_security_group_rules = {
    bastion_to_eks_api = {
      description              = "To ${local.eks_cluster_name}:443"
      protocol                 = "tcp"
      from_port                = "443"
      to_port                  = "443"
      type                     = "egress"
      security_group_id        = var.bastion_security_group_id
      source_security_group_id = aws_security_group.eks_cluster.id
    }
    bastion_to_eks_nodes_ssh = {
      description              = "To eks nodes over ssh"
      protocol                 = "tcp"
      from_port                = "22"
      to_port                  = "22"
      type                     = "egress"
      security_group_id        = var.bastion_security_group_id
      source_security_group_id = aws_security_group.eks_nodes.id
    }
    eks_api_from_bastion = {
      description              = "From Bastion over https"
      protocol                 = "tcp"
      from_port                = "443"
      to_port                  = "443"
      type                     = "ingress"
      security_group_id        = aws_security_group.eks_cluster.id
      source_security_group_id = var.bastion_security_group_id
    }
    eks_nodes_ssh_from_bastion = {
      description              = "From Bastion over ssh"
      protocol                 = "tcp"
      from_port                = "22"
      to_port                  = "22"
      type                     = "ingress"
      security_group_id        = aws_security_group.eks_nodes.id
      source_security_group_id = var.bastion_security_group_id
    }
  }
}
