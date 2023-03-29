locals {
  k8s_functions_sh_filename = "k8s-functions.sh"
  k8s_functions_sh_template = "k8s-functions.sh.tftpl"
  k8s_pre_setup_sh_filename = "k8s-pre-setup.sh"
  k8s_pre_setup_sh_template = "k8s-pre-setup.sh.tftpl"
  aws_auth_filename         = "aws-auth.yaml"
  aws_auth_template         = "aws-auth.yaml.tftpl"
  eniconfig_filename        = length(var.network_info.subnets.pod) != 0 ? "eniconfig.yaml" : ""
  eniconfig_template        = "eniconfig.yaml.tftpl"
  resources_directory       = path.cwd
  templates_dir             = "${path.module}/templates"

  templates = {
    k8s_functions_sh = {
      filename = local.k8s_functions_sh_filename
      content = templatefile("${local.templates_dir}/${local.k8s_functions_sh_template}", {
        kubeconfig_path   = var.eks_info.kubeconfig.path
        k8s_tunnel_port   = var.k8s_tunnel_port
        aws_auth_yaml     = basename(local.aws_auth_filename)
        eniconfig_yaml    = local.eniconfig_filename != "" ? basename(local.eniconfig_filename) : ""
        ssh_pvt_key_path  = var.ssh_key.path
        eks_cluster_arn   = var.eks_info.cluster.arn
        calico_version    = var.calico_version
        bastion_user      = var.bastion_info != null ? var.bastion_info.user : ""
        bastion_public_ip = var.bastion_info != null ? var.bastion_info.public_ip : ""
      })
    }

    k8s_presetup = {
      filename = local.k8s_pre_setup_sh_filename
      content = templatefile("${local.templates_dir}/${local.k8s_pre_setup_sh_template}", {
        k8s_functions_sh_filename = local.k8s_functions_sh_filename
      })
    }

    aws_auth = {
      filename = local.aws_auth_filename
      content = templatefile("${local.templates_dir}/${local.aws_auth_template}",
        {
          eks_node_role_arns   = toset(var.eks_info.nodes.roles[*].arn)
          eks_master_role_arns = toset(var.eks_info.cluster.roles[*].arn)
          eks_custom_role_maps = var.eks_info.cluster.custom_roles
      })

    }

    eni_config = {
      filename = local.eniconfig_filename
      content = templatefile("${local.templates_dir}/${local.eniconfig_template}",
        {
          security_group_id = var.eks_info.nodes.security_group_id
          subnets           = var.network_info.subnets.pod
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

resource "null_resource" "run_k8s_pre_setup" {
  triggers = {
    k8s_presetup_hash     = md5(local_file.templates["k8s_presetup"].content)
    k8s_functions_sh_hash = md5(local_file.templates["k8s_functions_sh"].content)
    aws_auth_hash         = md5(local_file.templates["aws_auth"].content)
    eni_config_hash       = try(md5(local_file.templates["eni_config"].content), "none")
  }

  provisioner "local-exec" {
    command     = basename(local_file.templates["k8s_presetup"].filename)
    interpreter = ["bash"]
    working_dir = local.resources_directory
  }

  depends_on = [
    local_file.templates,
  ]
}
