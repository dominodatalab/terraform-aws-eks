output "eks_oidc_provider" {
  description = "EKS OIDC provider"
  value = {
    eks = {
      oidc_provider = {
        create = false
        oidc = {
          id              = aws_iam_openid_connect_provider.oidc_provider.id
          arn             = aws_iam_openid_connect_provider.oidc_provider.arn
          url             = aws_iam_openid_connect_provider.oidc_provider.url
          thumbprint_list = aws_iam_openid_connect_provider.oidc_provider.thumbprint_list
        }
      }
    }
  }
}
