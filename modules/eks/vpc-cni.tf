
data "aws_eks_addon_version" "default_vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

data "aws_eks_addon" "vpc_cni" {
  addon_name   = "vpc-cni"
  cluster_name = aws_eks_cluster.this.name
}

locals {
  vpc_cni_config_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = tostring(try(var.eks.vpc_cni.prefix_delegation, false))
      ANNOTATE_POD_IP          = tostring(try(var.eks.vpc_cni.annotate_pod_ip, true))
    }
  })

  upgrade_addon_tpl = "${path.module}/templates/upgrade-addon.sh.tftpl"
  upgrade_addon_sh  = "${path.cwd}/upgrade-addon.sh"
}

resource "local_file" "upgrade_vpc_cni" {
  content = templatefile(local.upgrade_addon_tpl, {
    eks_cluster_name     = aws_eks_cluster.this.name
    k8s_version          = aws_eks_cluster.this.version
    aws_region           = var.region
    configuration_values = local.vpc_cni_config_values
    addon_name           = "vpc-cni"
    addon_version        = data.aws_eks_addon_version.default_vpc_cni.version
  })
  filename             = local.upgrade_addon_sh
  directory_permission = "0777"
  file_permission      = "0744"
}

resource "terraform_data" "upgrade_vpc_cni" {
  provisioner "local-exec" {
    command     = "bash ./${basename(local.upgrade_addon_sh)}"
    interpreter = ["bash", "-c"]
    working_dir = dirname(local_file.upgrade_vpc_cni.filename)
  }

  triggers_replace = [
    local_file.upgrade_vpc_cni.content_md5,
    data.aws_eks_addon.vpc_cni.addon_version,
    aws_eks_cluster.this.id
  ]
  depends_on = [local_file.upgrade_vpc_cni, aws_eks_cluster.this]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.default_vpc_cni.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values        = local.vpc_cni_config_values
  depends_on                  = [terraform_data.upgrade_vpc_cni]
}
