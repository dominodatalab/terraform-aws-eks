data "aws_eks_cluster" "this" {
  name = var.deploy_id
}

data "tls_certificate" "cluster_tls_certificate" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster_tls_certificate.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.cluster_tls_certificate.url
}
