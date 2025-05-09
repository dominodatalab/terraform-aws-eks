module "privatelink" {
  count            = var.privatelink.enabled ? 1 : 0
  source           = "./submodules/privatelink"
  deploy_id        = var.deploy_id
  network_info     = var.network_info
  privatelink      = var.privatelink
  oidc_provider_id = var.eks.create_oidc_provider ? aws_iam_openid_connect_provider.oidc_provider[0].id : null
}
