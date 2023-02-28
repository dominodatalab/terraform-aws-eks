locals {
  k8s_functions_sh_filename = "k8s-functions.sh"
  k8s_functions_sh_template = "k8s-functions.sh.tftpl"
  k8s_pre_setup_sh_filename = "k8s-pre-setup.sh"
  k8s_pre_setup_sh_template = "k8s-pre-setup.sh.tftpl"
  aws_auth_filename         = "aws-auth.yaml"
  aws_auth_template         = "aws-auth.yaml.tftpl"
  eniconfig_filename        = length(var.pod_subnets) != 0 ? "eniconfig.yaml" : ""
  eniconfig_template        = "eniconfig.yaml.tftpl"
  calico = {
    operator_url = "https://raw.githubusercontent.com/projectcalico/calico/${var.calico_version}/manifests/tigera-operator.yaml"
  }

  resources_directory = path.cwd
  templates_dir       = "${path.module}/templates"

  templates = {
    k8s_functions_sh = {
      filename = local.k8s_functions_sh_filename
      content = templatefile("${local.templates_dir}/${local.k8s_functions_sh_template}", {
        kubeconfig_path     = var.kubeconfig_path
        k8s_tunnel_port     = var.k8s_tunnel_port
        aws_auth_yaml       = basename(local.aws_auth_filename)
        eniconfig_yaml      = local.eniconfig_filename != "" ? basename(local.eniconfig_filename) : ""
        calico_operator_url = local.calico.operator_url
        bastion_user        = var.bastion_user
        bastion_public_ip   = var.bastion_public_ip
        ssh_pvt_key_path    = var.ssh_pvt_key_path
        eks_cluster_arn     = var.eks_cluster_arn
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
          eks_node_role_arns   = toset(var.eks_node_role_arns)
          eks_master_role_arns = toset(var.eks_master_role_arns)
          eks_custom_role_maps = var.eks_custom_role_maps
      })

    }

    eni_config = {
      filename = local.eniconfig_filename
      content = templatefile("${local.templates_dir}/${local.eniconfig_template}",
        {
          security_group_id = var.security_group_id
          subnets           = var.pod_subnets
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
    script_hash = md5(local_file.templates["k8s_presetup"].content)
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
