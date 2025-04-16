eks = {
  k8s_version        = "1.30"

}
flyte = {
  compute_namespace         = "domino-compute"
  enabled                   = true
  force_destroy_on_deletion = true
  platform_namespace        = "domino-platform"
}

irsa_policies = [
{
    name                = "aws-efs-csi-driver-controller"
    namespace           = "domino-platform"
    serviceaccount_name = "aws-efs-csi-driver-controller"
  },
  {
    name                = "aws-ebs-csi-driver-controller"
    namespace           = "domino-platform"
    serviceaccount_name = "aws-ebs-csi-driver-controller"
  },
  {
    name                = "cluster-autoscaler"
    namespace           = "domino-platform"
    serviceaccount_name = "cluster-autoscaler"
  },
    {
    name                = "cost-analyzer"
    namespace           = "domino-platform"
    serviceaccount_name = "cost-analyzer"
  },
    {
    name                = "domino-admin-toolkit"
    namespace           = "domino-platform"
    serviceaccount_name = "domino-admin-toolkit"
  },
      {
    name                = "domino-data-importer"
    namespace           = "domino-platform"
    serviceaccount_name = "domino-data-importer"
  },
        {
    name                = "external-dns"
    namespace           = "domino-platform"
    serviceaccount_name = "external-dns"
  },
          {
    name                = "fluentd"
    namespace           = "domino-platform"
    serviceaccount_name = "fluentd"
  },
            {
    name                = "hephaestus"
    namespace           = "domino-platform"
    serviceaccount_name = "hephaestus"
  },
            {
    name                = "mlflow"
    namespace           = "domino-platform"
    serviceaccount_name = "mlflow"
  },
              {
    name                = "nucleus-ecr-credential-refresher"
    namespace           = "domino-platform"
    serviceaccount_name = "nucleus-ecr-credential-refresher"
  },
                {
    name                = "nucleus"
    namespace           = "domino-platform"
    serviceaccount_name = "nucleus"
  }


]

use_fips_endpoint = false
