data "aws_default_tags" "this" {}

locals {
  security_group_rules = {
    single_node_inbound_ssh = {
      protocol    = "tcp"
      from_port   = "22"
      to_port     = "22"
      type        = "ingress"
      description = "Inbound ssh"
      cidr_blocks = var.single_node.authorized_ssh_ip_ranges
    }
  }
  ami_name  = try(var.single_node.ami.name_prefix, null) != null ? "${var.single_node.ami.name_prefix}${var.eks_info.cluster.version}*" : "amazon-eks-node-${var.eks_info.cluster.version}*"
  ami_owner = coalesce(var.single_node.ami.owner, "602401143452") #amazon

}

data "aws_ami" "single_node" {
  most_recent = true
  owners      = [local.ami_owner]

  filter {
    name   = "name"
    values = [local.ami_name]
  }
}


data "aws_eks_addon_version" "default" {
  for_each           = toset(var.eks_info.cluster.addons)
  addon_name         = each.key
  kubernetes_version = var.eks_info.cluster.version
}

resource "terraform_data" "node_is_ready" {
  count = try(fileexists(var.eks_info.k8s_pre_setup_sh_file), false) ? 1 : 0

  # Even though the node is ready coredns hangs or takes 15m, waiting a bit reduces it to 15s.
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1801
  provisioner "local-exec" {
    command     = "bash ./${basename(var.eks_info.k8s_pre_setup_sh_file)} wait_for_node && sleep 60"
    interpreter = ["bash", "-c"]
    working_dir = dirname(var.eks_info.k8s_pre_setup_sh_file)
  }

  triggers_replace = [
    filemd5(var.eks_info.k8s_pre_setup_sh_file),
    aws_instance.single_node.id
  ]
  depends_on = [aws_instance.single_node]
}


resource "aws_eks_addon" "this" {
  for_each                    = toset(var.eks_info.cluster.addons)
  cluster_name                = var.eks_info.cluster.specs.name
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.default[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [terraform_data.node_is_ready]
}

resource "terraform_data" "calico_setup" {
  count = try(fileexists(var.eks_info.k8s_pre_setup_sh_file), false) ? 1 : 0

  triggers_replace = [
    filemd5(var.eks_info.k8s_pre_setup_sh_file)
  ]

  provisioner "local-exec" {
    command     = "bash ./${basename(var.eks_info.k8s_pre_setup_sh_file)} install_calico"
    interpreter = ["bash", "-c"]
    working_dir = dirname(var.eks_info.k8s_pre_setup_sh_file)
  }

  depends_on = [terraform_data.node_is_ready]
}
