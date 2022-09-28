locals {
  mallory_config_filename       = "mallory.json"
  mallory_container_name        = "mallory_k8s_tunnel"
  mallory_config_path_container = "/root/.config/${local.mallory_config_filename}"
  pvt_key_path_container        = "/root/${basename(var.ssh_pvt_key_path)}"
  k8s_functions_sh_filename     = "k8s-functions.sh"
  k8s_functions_sh_template     = "k8s-functions.sh.tftpl"
  k8s_pre_setup_sh_filename     = "k8s-pre-setup.sh"
  k8s_pre_setup_sh_template     = "k8s-pre-setup.sh.tftpl"
  aws_auth_filename             = "aws-auth.yaml"
  aws_auth_template             = "aws-auth.yaml.tftpl"
  calico = {
    operator_url         = "https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/${var.calico_version}/config/master/calico-operator.yaml"
    custom_resources_url = "https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/${var.calico_version}/config/master/calico-crs.yaml"
  }

  k8s_tunnel_command = "docker run --rm --name ${local.mallory_container_name} -d -v $PWD/${local.mallory_config_filename}:${local.mallory_config_path_container} -p ${var.mallory_local_normal_port}:${var.mallory_local_normal_port} -p ${var.mallory_local_smart_port}:${var.mallory_local_smart_port} -v ${var.ssh_pvt_key_path}:${local.pvt_key_path_container} zoobab/mallory"

  resources_directory = path.cwd
  templates_dir       = "${path.module}/templates"

  templates = {
    k8s_functions_sh = {
      filename = local.k8s_functions_sh_filename
      content = templatefile("${local.templates_dir}/${local.k8s_functions_sh_template}", {
        kubeconfig_path             = var.kubeconfig_path
        k8s_tunnel_command          = local.k8s_tunnel_command
        mallory_port                = var.mallory_local_smart_port
        mallory_container_name      = local.mallory_container_name
        mallory_config_file         = local.mallory_config_filename
        aws_auth_yaml               = basename(local.aws_auth_filename)
        calico_operator_url         = local.calico.operator_url
        calico_custom_resources_url = local.calico.custom_resources_url
      })
    }

    k8s_presetup = {
      filename = local.k8s_pre_setup_sh_filename
      content = templatefile("${local.templates_dir}/${local.k8s_pre_setup_sh_template}", {
        k8s_functions_sh_filename = local.k8s_functions_sh_filename
      })
    }

    mallory_k8s_tunnel = {
      filename = local.mallory_config_filename
      content = jsonencode(
        {
          "id_rsa"       = local.pvt_key_path_container
          "local_smart"  = ":${var.mallory_local_smart_port}"
          "local_normal" = ":${var.mallory_local_normal_port}"
          "remote"       = "ssh://${var.bastion_user}@${var.bastion_public_ip}:22"
          "blocked"      = [var.k8s_cluster_endpoint]
    }) }

    aws_auth = {
      filename = local.aws_auth_filename
      content = templatefile("${local.templates_dir}/${local.aws_auth_template}",
        {
          eks_node_role_arns   = toset(var.eks_node_role_arns)
          eks_master_role_arns = toset(var.eks_master_role_arns)
      })

    }
  }
}

resource "local_file" "templates" {
  for_each             = { for k, v in local.templates : k => v }
  content              = each.value.content
  filename             = "${local.resources_directory}/${each.value.filename}"
  directory_permission = "0777"
  file_permission      = "0744"
}

resource "null_resource" "run_k8s_pre_setup" {
  provisioner "local-exec" {
    command     = basename(local_file.templates["k8s_presetup"].filename)
    interpreter = ["bash", "-ex"]
    working_dir = local.resources_directory
  }

  depends_on = [
    local_file.templates,
  ]
}
