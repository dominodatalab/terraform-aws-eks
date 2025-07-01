locals {
  # See `Subnet requirements for clusters` on https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html
  eks_unsupported_az_ids = ["use1-az3", "usw1-az2", "cac1-az3"]

  eks_supported_subnets = {
    for s in var.network_info.subnets.private : s.az_id => s
    if !contains(local.eks_unsupported_az_ids, s.az_id)
  }

  eks_number_of_subnets = length(local.eks_supported_subnets) >= 3 ? 3 : 2

  eks_control_plane_subnet_ids = [
    for az_id in slice(sort(keys(local.eks_supported_subnets)), 0, local.eks_number_of_subnets) :
    local.eks_supported_subnets[az_id].subnet_id
  ]
}

resource "aws_security_group" "eks_cluster" {
  name        = "${local.eks_cluster_name}-cluster"
  description = "EKS cluster security group"
  vpc_id      = var.network_info.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [description, name]
  }
  tags = {
    "Name"                                            = "${local.eks_cluster_name}-eks-cluster"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "eks_cluster" {
  for_each = local.eks_cluster_security_group_rules

  security_group_id        = aws_security_group.eks_cluster.id
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  type                     = each.value.type
  description              = each.value.description
  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.eks_cluster_name}/cluster"
  retention_in_days = 365
}

data "aws_caller_identity" "cluster_aws_account" {
  provider = aws.eks
}

resource "aws_eks_cluster" "this" {
  provider = aws.eks

  name                      = local.eks_cluster_name
  role_arn                  = aws_iam_role.eks_cluster.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  version                   = var.eks.k8s_version

  encryption_config {
    provider {
      key_arn = local.kms_key_arn
    }

    resources = ["secrets"]
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = var.eks.service_ipv4_cidr
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = var.eks.public_access.enabled
    public_access_cidrs     = var.eks.public_access.cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
    subnet_ids              = local.eks_control_plane_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_security_group_rule.eks_cluster,
    aws_security_group_rule.node,
    aws_cloudwatch_log_group.eks_cluster
  ]

  lifecycle {
    ignore_changes = [
      encryption_config,
      kubernetes_network_config,
      vpc_config[0].subnet_ids
    ]
  }
}

data "tls_certificate" "cluster_tls_certificate" {
  count = var.eks.oidc_provider.create ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

moved {
  from = aws_iam_openid_connect_provider.oidc_provider
  to   = aws_iam_openid_connect_provider.oidc_provider[0]
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  count           = var.eks.oidc_provider.create ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster_tls_certificate[0].certificates[*].sha1_fingerprint
  url             = data.tls_certificate.cluster_tls_certificate[0].url
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    when    = create
    command = "aws eks update-kubeconfig --kubeconfig ${self.triggers.kubeconfig_file} --region ${self.triggers.region} --name ${self.triggers.cluster_name} --alias ${self.triggers.cluster_name} ${local.kubeconfig.extra_args}"
    environment = {
      AWS_USE_FIPS_ENDPOINT = tostring(var.use_fips_endpoint)
    }
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if (($(kubectl config --kubeconfig ${self.triggers.kubeconfig_file} get-contexts -o name | grep -v ${self.triggers.cluster_name}| wc -l) > 0 )); then
        kubectl config --kubeconfig ${self.triggers.kubeconfig_file} delete-cluster ${self.triggers.cluster_name}
        kubectl config --kubeconfig ${self.triggers.kubeconfig_file} delete-context ${self.triggers.cluster_name}
      else
        rm -f ${self.triggers.kubeconfig_file} "${self.triggers.kubeconfig_file}-proxy" || true
      fi
    EOT
  }
  triggers = {
    domino_eks_cluster_ca = aws_eks_cluster.this.certificate_authority[0].data
    cluster_name          = aws_eks_cluster.this.name
    kubeconfig_file       = local.kubeconfig.path
    region                = var.region
  }
  depends_on = [aws_eks_cluster.this]
}
