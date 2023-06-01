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
    service_ipv4_cidr = "172.20.0.0/16"
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = var.eks.public_access.enabled
    public_access_cidrs     = var.eks.public_access.cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
    subnet_ids              = [for s in var.network_info.subnets.private : s.subnet_id]
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
    ]
  }
}

data "tls_certificate" "cluster_tls_certificate" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster_tls_certificate.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.cluster_tls_certificate.url
}


resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_name                  = "vpc-cni"
  configuration_values = jsonencode({
    env = merge(
      {},
      try(var.eks.vpc_cni.prefix_delegation, false) ? { ENABLE_PREFIX_DELEGATION = "true" } : {}
    )
  })
}

resource "aws_eks_addon" "this" {
  for_each                    = toset(var.eks.cluster_addons)
  cluster_name                = aws_eks_cluster.this.name
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_name                  = each.key

  depends_on = [
    aws_eks_node_group.node_groups,
  ]
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    when    = create
    command = "aws eks update-kubeconfig --kubeconfig ${self.triggers.kubeconfig_file} --region ${self.triggers.region} --name ${self.triggers.cluster_name} --alias ${self.triggers.cluster_name} ${local.kubeconfig.extra_args}"
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
