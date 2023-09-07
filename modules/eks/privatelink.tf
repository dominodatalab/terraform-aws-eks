module "privatelink" {
  count            = var.privatelink.enabled ? 1 : 0
  source           = "./submodules/privatelink"
  deploy_id        = var.deploy_id
  region           = var.region
  network_info     = var.network_info
  privatelink      = var.privatelink
  oidc_provider_id = aws_iam_openid_connect_provider.oidc_provider.id
}