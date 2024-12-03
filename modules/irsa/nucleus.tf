variable "node_iam_policies" {
  description = "Additional IAM Policy Arns for Nodes"
  type        = list(string)
}

variable "nucleus" {
  description = "Config to enable irsa for external-dns"

  type = object({
    namespace           = optional(string, "domino-platform")
    serviceaccount_name = optional(string, "nucleus")
  })

  default = {}
}

resource "aws_iam_policy" "custom_eks_node_policy" {
  name   = "${var.deploy_id}-nodes-custom"
  path   = "/"
  policy = data.aws_iam_policy_document.custom_eks_node_policy.json
}

locals {
  eks_aws_node_iam_policies = [
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonSSMManagedInstanceCore",
    "AmazonElasticFileSystemReadOnlyAccess",
  ]

  custom_node_policies = concat([aws_iam_policy.custom_eks_node_policy.arn], var.node_iam_policies)
}

data "aws_iam_policy_document" "eks_nodes" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${local.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${local.eks_cluster_name}-node-role-but-not"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition : {
          StringEquals : {
            "${trimprefix(local.oidc_provider_url, "https://")}:aud" : "sts.amazonaws.com"
            "${trimprefix(local.oidc_provider_url, "https://")}:sub" : "system:serviceaccount:${var.nucleus.namespace}:${var.nucleus.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_eks_nodes" {
  for_each   = toset(local.eks_aws_node_iam_policies)
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.key}"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "custom_eks_nodes" {
  count      = length(local.custom_node_policies)
  policy_arn = element(local.custom_node_policies, count.index)
  role       = aws_iam_role.eks_nodes.name
}
