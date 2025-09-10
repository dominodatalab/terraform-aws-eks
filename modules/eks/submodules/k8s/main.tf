resource "random_integer" "port" {
  min = 49152
  max = 65535
}

locals {
  k8s_functions_sh_filename = "k8s-functions.sh"
  k8s_functions_sh_template = "k8s-functions.sh.tftpl"
  k8s_pre_setup_sh_file     = "k8s-pre-setup.sh"
  k8s_pre_setup_sh_template = "k8s-pre-setup.sh.tftpl"
  aws_auth_filename         = "aws-auth.yaml"
  aws_auth_template         = "aws-auth.yaml.tftpl"
  resources_directory       = path.cwd
  templates_dir             = "${path.module}/templates"

  k8s_functions_sh = {
    filename = local.k8s_functions_sh_filename
    content = templatefile("${local.templates_dir}/${local.k8s_functions_sh_template}", {
      kubeconfig_path                       = var.eks_info.kubeconfig.path
      k8s_tunnel_port                       = random_integer.port.result
      aws_auth_yaml                         = basename(local.aws_auth_filename)
      ssh_pvt_key_path                      = var.ssh_key.path
      eks_cluster_arn                       = var.eks_info.cluster.arn
      bastion_user                          = var.bastion_info != null ? var.bastion_info.user : ""
      bastion_public_ip                     = var.bastion_info != null ? var.bastion_info.public_ip : ""
      calico_version                        = var.eks_info.calico.version
      calico_fips_mode                      = var.use_fips_endpoint ? "Enabled" : "Disabled"
      calico_image_registry                 = var.eks_info.calico.image_registry
      calico_karpenter_node_selector        = var.karpenter.enabled ? "karpenter" : "platform"
      karpenter_namespace                   = var.karpenter.namespace
      karpenter_version                     = var.karpenter.version
      karpenter_vm_memory_overhead_percent  = var.karpenter.vm_memory_overhead_percent
      delete_karpenter_instances_on_destroy = tostring(var.karpenter.delete_instances_on_destroy)
      cluster_name                          = var.cluster_name
      region                                = var.region
    })
  }

  aws_auth = {
    filename = local.aws_auth_filename
    content = templatefile("${local.templates_dir}/${local.aws_auth_template}",
      {
        nodes_master         = try(var.eks_info.nodes.nodes_master, false)
        eks_node_role_arns   = toset(var.eks_info.nodes.roles[*].arn)
        eks_master_role_arns = toset(var.eks_info.cluster.roles[*].arn)
        eks_custom_role_maps = var.eks_info.cluster.custom_roles
    })
  }

  templates = {
    k8s_functions_sh = local.k8s_functions_sh
    aws_auth         = local.aws_auth

    k8s_presetup = {
      filename = local.k8s_pre_setup_sh_file
      content = templatefile("${local.templates_dir}/${local.k8s_pre_setup_sh_template}", {
        k8s_functions_sh_filename = local.k8s_functions_sh.filename
        hash                      = join("-", [md5(local.k8s_functions_sh.content), md5(local.aws_auth.content)])
        use_fips_endpoint         = tostring(var.use_fips_endpoint)
      })
    }
  }
}

resource "local_file" "templates" {
  for_each             = { for k, v in local.templates : k => v if v.filename != "" }
  content              = each.value.content
  filename             = "${local.resources_directory}/${each.value.filename}"
  directory_permission = "0777"
  file_permission      = "0744"
}

locals {
  change_hash = join("-", [for tpl in sort(keys(local_file.templates)) : local_file.templates[tpl].content_md5])
}
