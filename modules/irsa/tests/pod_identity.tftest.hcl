# checkov and trivy see an aws_iam_policy built from jsonencode() or aws_iam_policy_document,
# and see nothing when the body is templatefile(), which is how every apps-policies file reaches
# aws_iam_policy.this. Nothing else in CI looks inside those documents.
#
# mock_provider only. Everything asserted is a resource input or a templatefile() rendering, so
# every run is command = plan.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-west-2"
    }
  }
}

# configuration_aliases makes aws.global mandatory even with external_dns off.
mock_provider "aws" {
  alias = "global"
}

variables {
  eks_info = {
    nodes = { roles = [] }
    cluster = {
      arn = "arn:aws:eks:us-west-2:123456789012:cluster/test-deploy"
      specs = {
        name       = "test-deploy"
        account_id = "123456789012"
      }
      oidc = {
        arn             = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
        id              = "EXAMPLED539D4633E53DE1B716D3041E"
        url             = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
        thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
      }
    }
  }
}

# Inline policies, so this run does not depend on any apps-policies file.
run "trust_policy_and_association" {
  command = plan

  variables {
    additional_irsa_configs = [
      {
        name                = "pi-entry"
        namespace           = "domino-platform"
        serviceaccount_name = "pi-app"
        pod_identity        = true
        policy              = jsonencode({ Version = "2012-10-17", Statement = [] })
      },
      {
        name                = "irsa-entry"
        namespace           = "domino-platform"
        serviceaccount_name = "irsa-app"
        pod_identity        = false
        policy              = jsonencode({ Version = "2012-10-17", Statement = [] })
      },
    ]
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["pi-entry"].assume_role_policy).Statement[0].Principal.Service == "pods.eks.amazonaws.com"
    error_message = "A pod_identity role must trust the pods.eks.amazonaws.com service."
  }

  assert {
    condition     = toset(flatten([jsondecode(aws_iam_role.this["pi-entry"].assume_role_policy).Statement[0].Action])) == toset(["sts:AssumeRole", "sts:TagSession"])
    error_message = "A pod_identity trust policy must allow exactly sts:AssumeRole and sts:TagSession."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["pi-entry"].assume_role_policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "123456789012"
    error_message = "Without aws:SourceAccount, the role is assumable on behalf of pods in any account."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["pi-entry"].assume_role_policy).Statement[0].Condition.ArnEquals["aws:SourceArn"] == "arn:aws:eks:us-west-2:123456789012:cluster/test-deploy"
    error_message = "Without aws:SourceArn naming this cluster, the role is assumable on behalf of a pod identity association on another cluster."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["irsa-entry"].assume_role_policy).Statement[0].Condition.StringEquals["oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub"] == "system:serviceaccount:domino-platform:irsa-app"
    error_message = "An IRSA trust policy must condition :sub on the service account it binds."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["irsa-entry"].assume_role_policy).Statement[0].Condition.StringEquals["oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:aud"] == "sts.amazonaws.com"
    error_message = "An IRSA trust policy must condition :aud on sts.amazonaws.com, or any web identity token can be exchanged for this role."
  }

  assert {
    condition     = contains(keys(aws_eks_pod_identity_association.this), "pi-entry")
    error_message = "A pod_identity entry must get a pod identity association."
  }

  assert {
    condition     = !contains(keys(aws_eks_pod_identity_association.this), "irsa-entry")
    error_message = "An IRSA entry must not get a pod identity association: nothing would ever call it, and it would collide with the one-binding-per-service-account precondition."
  }

  assert {
    condition     = aws_eks_pod_identity_association.this["pi-entry"].namespace == "domino-platform" && aws_eks_pod_identity_association.this["pi-entry"].service_account == "pi-app"
    error_message = "The pod identity association must bind the namespace and service account from its config entry."
  }
}

# Prefixed bucket, unprefixed bucket, and a KMS bucket whose key is outside the cluster region.
run "filetask_objectstore_scoping" {
  command = plan

  variables {
    filetask_objectstore = {
      enabled             = true
      namespace           = "domino-compute"
      serviceaccount_name = "domino-filetask-objectstore"
      buckets = [
        { name = "prefixed-bucket", prefix = "datasets" },
        { name = "unprefixed-bucket" },
        { name = "kms-bucket", prefix = "kms-data", kms_key_arn = "arn:aws:kms:eu-west-1:123456789012:key/11111111-2222-3333-4444-555555555555" },
      ]
    }
  }

  assert {
    condition     = toset(jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement[0].Condition.StringLike["s3:prefix"]) == toset(["datasets", "datasets/*"])
    error_message = "The prefixed bucket's ListBucket statement must carry StringLike on s3:prefix with both the bare prefix and the prefix/* form."
  }

  assert {
    # StringLike on an absent s3:prefix never matches, so a condition here would deny every list.
    condition     = !contains(keys(jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement[1]), "Condition")
    error_message = "The unprefixed bucket's ListBucket statement must carry no Condition."
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement :
      alltrue([for a in flatten([s.Action]) : !can(regex("^s3:\\*$", a))])
    ])
    error_message = "No statement may grant the s3:* wildcard action."
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement :
      alltrue([
        for a in flatten([s.Action]) :
        !startswith(a, "s3:") || alltrue([for r in flatten([s.Resource]) : r != "*"])
      ])
    ])
    error_message = "No s3: action may be granted on a bare * resource."
  }

  assert {
    # Closed set, so an appended statement scoped to the wrong bucket is caught too.
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement :
      alltrue([
        for r in flatten([s.Resource]) : contains([
          "arn:aws:s3:::prefixed-bucket", "arn:aws:s3:::prefixed-bucket/datasets/*",
          "arn:aws:s3:::unprefixed-bucket", "arn:aws:s3:::unprefixed-bucket/*",
          "arn:aws:s3:::kms-bucket", "arn:aws:s3:::kms-bucket/kms-data/*",
        ], r)
      ]) if anytrue([for a in flatten([s.Action]) : startswith(a, "s3:")])
    ])
    error_message = "Every s3: statement must name only the configured buckets and their prefix paths."
  }

  assert {
    condition     = jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement[6].Resource == "arn:aws:s3:::prefixed-bucket/datasets/*"
    error_message = "The prefixed bucket's object statement must be confined to its prefix path, not the whole bucket."
  }

  assert {
    condition     = jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement[7].Resource == "arn:aws:s3:::unprefixed-bucket/*"
    error_message = "The unprefixed bucket's object statement covers the whole bucket, which is correct only because it has no prefix."
  }

  assert {
    condition     = jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement[8].Resource == "arn:aws:s3:::kms-bucket/kms-data/*"
    error_message = "The kms bucket's object statement must be confined to its prefix path."
  }

  assert {
    # The key's own region, not the cluster's: SSE-KMS keeps the key in the bucket's region.
    condition     = jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement[9].Condition.StringEquals["kms:ViaService"] == "s3.eu-west-1.amazonaws.com"
    error_message = "The KMS statement's kms:ViaService must name the key's own region, not the cluster's region."
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement :
      s if contains(flatten([s.Action]), "s3files:GetFileSystem")
    ]) == 1
    error_message = "s3files:GetFileSystem must appear exactly once."
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.this["filetask-objectstore"].policy).Statement :
      try(s.Sid, null) == null || can(regex("^[A-Za-z0-9]+$", s.Sid))
    ])
    error_message = "Every Sid must match ^[A-Za-z0-9]+$: IAM accepts only letters and digits in a Sid and rejects the whole policy otherwise."
  }
}

# Nothing else renders these files until a config entry names one, so a typo or a missing
# interpolation variable surfaces only here.
run "policy_library_renders" {
  command = plan

  variables {
    additional_irsa_configs = [
      for name in [
        "aws-ebs-csi-driver-controller",
        "aws-efs-csi-driver-controller",
        "cluster-autoscaler",
        "cost-analyzer",
        "domino-admin-toolkit",
        "domino-data-importer",
        "fluentd",
        "hephaestus",
        "mlflow",
        "nucleus-ecr-credential-refresher",
        "nucleus",
        ] : {
        name                = name
        namespace           = "domino-platform"
        serviceaccount_name = name
        policy              = null
      }
    ]
    filetask_objectstore = {
      enabled             = true
      namespace           = "domino-compute"
      serviceaccount_name = "domino-filetask-objectstore"
      buckets             = [{ name = "library-bucket" }]
    }
  }

  assert {
    condition     = length(aws_iam_policy.this) == 12
    error_message = "Every apps-policies file plus filetask-objectstore must render one policy: 11 library entries here plus the filetask-objectstore entry."
  }

  assert {
    condition     = alltrue([for k, p in aws_iam_policy.this : can(jsondecode(p.policy))])
    error_message = "Every rendered policy must decode as valid JSON. A hand-edited apps-policies file that breaks templatefile() interpolation or produces malformed JSON is caught only here."
  }
}
