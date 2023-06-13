output "change_hash" {
  description = "Hash of all templated files"
  value       = local.change_hash
}

output "filepath" {
  description = "Filename of primary script"
  value       = "${local.resources_directory}/${local.k8s_pre_setup_sh_file}"
}

output "resources_directory" {
  description = "Directory for provisioned scripts and templated files"
  value       = local.resources_directory
}
