locals {
  ppi = var.platform_pod_identity

  ppi_policy_vars = {
    partition  = local.policy_vars.partition
    account_id = local.policy_vars.account_id
    region     = local.policy_vars.region

    cluster_name       = local.name_prefix
    cluster_arn        = var.eks_info.cluster.arn
    kms_key_arn        = local.ppi.kms_key_arn
    efs_file_system_id = local.ppi.efs_file_system_id
    ecr_repo_prefix    = coalesce(local.ppi.ecr_repo_prefix, lower(local.name_prefix))
    route53_zone_id    = local.ppi.route53_zone_id
    bucket             = ""
    ecr_token          = false
  }

  ppi_dir = "${path.module}/apps-policies/platform"

  # Every preset binds one service account through Pod Identity. `policy` is rendered from a
  # template so each role only receives what its workload needs; ebs-csi uses the AWS managed
  # policy instead.
  ppi_presets = {
    ebs-csi = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "aws-ebs-csi-driver-controller"
      policy              = null
      managed_policy_arns = ["arn:${local.policy_vars.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
    }
    efs-csi = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "aws-efs-csi-driver-controller"
      policy              = local.ppi.efs_file_system_id == null ? null : templatefile("${local.ppi_dir}/efs-csi.json.tftpl", local.ppi_policy_vars)
      managed_policy_arns = []
    }
    cluster-autoscaler = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "cluster-autoscaler"
      policy              = templatefile("${local.ppi_dir}/cluster-autoscaler.json.tftpl", local.ppi_policy_vars)
      managed_policy_arns = []
    }
    domino-admin-toolkit = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "domino-admin-toolkit"
      policy              = templatefile("${local.ppi_dir}/domino-admin-toolkit.json.tftpl", local.ppi_policy_vars)
      managed_policy_arns = []
    }
    domino-data-importer = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "domino-data-importer"
      policy              = local.ppi.buckets == null ? null : templatefile("${local.ppi_dir}/bucket.json.tftpl", merge(local.ppi_policy_vars, { bucket = local.ppi.buckets.backups }))
      managed_policy_arns = []
    }
    fluentd = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "fluentd"
      policy              = local.ppi.buckets == null ? null : templatefile("${local.ppi_dir}/bucket.json.tftpl", merge(local.ppi_policy_vars, { bucket = local.ppi.buckets.logs }))
      managed_policy_arns = []
    }
    mlflow = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "mlflow"
      policy              = local.ppi.buckets == null ? null : templatefile("${local.ppi_dir}/bucket.json.tftpl", merge(local.ppi_policy_vars, { bucket = local.ppi.buckets.blobs }))
      managed_policy_arns = []
    }
    nucleus = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "nucleus"
      policy              = local.ppi.buckets == null ? null : templatefile("${local.ppi_dir}/bucket.json.tftpl", merge(local.ppi_policy_vars, { bucket = local.ppi.buckets.blobs, ecr_token = true }))
      managed_policy_arns = []
    }
    nucleus-ecr-credential-refresher = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "nucleus-ecr-credential-refresher"
      policy              = templatefile("${local.ppi_dir}/ecr-token.json.tftpl", local.ppi_policy_vars)
      managed_policy_arns = []
    }
    hephaestus = {
      namespace           = local.ppi.compute_namespace
      serviceaccount_name = "hephaestus-buildkit"
      policy              = templatefile("${local.ppi_dir}/hephaestus.json.tftpl", local.ppi_policy_vars)
      managed_policy_arns = []
    }
    external-dns = {
      namespace           = local.ppi.platform_namespace
      serviceaccount_name = "external-dns"
      policy              = local.ppi.route53_zone_id == null ? null : templatefile("${local.ppi_dir}/external-dns.json.tftpl", local.ppi_policy_vars)
      managed_policy_arns = []
    }
  }

  # A preset whose inputs are missing (no EFS, no zone id) has neither a policy nor a managed
  # policy and is skipped rather than failing the plan.
  platform_pod_identity_configs = local.ppi.enabled ? [
    for name, c in local.ppi_presets : merge(c, { name = name, pod_identity = true })
    if !contains(local.ppi.disabled, name) && (c.policy != null || length(c.managed_policy_arns) > 0)
  ] : []
}
