# S3 Files dataset storage: the named counterpart to additional-pod-identity-configs.tf, in the
# same shape as modules/irsa/external-dns.tf and netapp-trident-operator.tf. The policies are
# written out here rather than passed in as rendered JSON so that the grants Domino needs are
# readable in the public module -- for customers running their own Terraform this file is what
# applies, and for everyone else it is the reference to copy.

locals {
  filetask_enabled = var.filetask_objectstore.enabled && length(var.filetask_objectstore.buckets) > 0
  filetask_buckets = local.filetask_enabled ? var.filetask_objectstore.buckets : []

  # Empty string rather than null for an unprefixed bucket, so the comparisons below stay simple.
  filetask_prefixes    = [for b in local.filetask_buckets : b.prefix == null ? "" : trim(b.prefix, "/")]
  filetask_bucket_arns = [for b in local.filetask_buckets : "arn:${data.aws_partition.current.partition}:s3:::${b.name}"]
  filetask_object_arns = [
    for i, b in local.filetask_buckets :
    local.filetask_prefixes[i] == "" ? "${local.filetask_bucket_arns[i]}/*" : "${local.filetask_bucket_arns[i]}/${local.filetask_prefixes[i]}/*"
  ]

  # Carries the original index so the Sid matches the bucket it belongs to even though the
  # unencrypted buckets are filtered out.
  filetask_kms = [
    for i, b in local.filetask_buckets : {
      index      = i
      key_arn    = b.kms_key_arn
      key_region = split(":", b.kms_key_arn)[3]
      bucket_arn = local.filetask_bucket_arns[i]
      object_arn = local.filetask_object_arns[i]
    } if b.kms_key_arn != null
  ]

  filetask_file_system_arn = "arn:${data.aws_partition.current.partition}:s3files:*:*:file-system/*"
}

# The task identity: what the s3-native filetask pods use to reach the bucket through the S3 API.
data "aws_iam_policy_document" "filetask_objectstore" {
  count = local.filetask_enabled ? 1 : 0

  dynamic "statement" {
    for_each = local.filetask_buckets
    content {
      sid       = "ListPrefix${statement.key}"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [local.filetask_bucket_arns[statement.key]]

      dynamic "condition" {
        # An unprefixed bucket gets no condition at all: StringLike on the absent s3:prefix key
        # never matches, so adding one would deny every list rather than widen it.
        for_each = local.filetask_prefixes[statement.key] == "" ? [] : [local.filetask_prefixes[statement.key]]
        content {
          test     = "StringLike"
          variable = "s3:prefix"
          # Both forms: a request for exactly `datasets` does not match `datasets/*`.
          values = [condition.value, "${condition.value}/*"]
        }
      }
    }
  }

  dynamic "statement" {
    for_each = local.filetask_buckets
    content {
      # Cannot carry a prefix condition -- AWS rejects the statement -- so delete-s3 confines
      # itself to the prefix client-side.
      sid       = "MultipartListing${statement.key}"
      effect    = "Allow"
      actions   = ["s3:ListBucketMultipartUploads"]
      resources = [local.filetask_bucket_arns[statement.key]]
    }
  }

  dynamic "statement" {
    for_each = local.filetask_buckets
    content {
      sid    = "Objects${statement.key}"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
      ]
      resources = [local.filetask_object_arns[statement.key]]
    }
  }

  dynamic "statement" {
    for_each = local.filetask_kms
    content {
      sid       = "ObjectEncryption${statement.value.index}"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [statement.value.key_arn]

      # Without both, the pods could decrypt everything else the key protects -- with a
      # deployment-managed key, volumes and secrets. The region is the key's, not the cluster's:
      # SSE-KMS keeps the key in the bucket's region.
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        # dns_suffix rather than a literal: ViaService is an endpoint DNS name, so it is
        # s3.<region>.amazonaws.com.cn in China. A service principal, by contrast, stays
        # amazonaws.com in every partition -- which is why main.tf hardcodes that one.
        values = ["s3.${statement.value.key_region}.${data.aws_partition.current.dns_suffix}"]
      }

      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values   = [statement.value.bucket_arn, statement.value.object_arn]
      }
    }
  }

  # Once, not per bucket: the call takes a file system id, not a bucket. Required by validate-s3.
  statement {
    sid       = "DescribeFileSystems"
    effect    = "Allow"
    actions   = ["s3files:GetFileSystem"]
    resources = [local.filetask_file_system_arn]
  }
}

resource "aws_iam_policy" "filetask_objectstore" {
  count = local.filetask_enabled ? 1 : 0

  name   = "${local.name_prefix}-filetask-objectstore"
  path   = "/"
  policy = data.aws_iam_policy_document.filetask_objectstore[0].json
}

resource "aws_iam_role" "filetask_objectstore" {
  count = local.filetask_enabled ? 1 : 0

  name               = "${local.name_prefix}-filetask-objectstore"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  lifecycle {
    precondition {
      # Configuring this feature *and* a matching additional_pod_identity_configs entry duplicates
      # the IAM role and policy names and creates a second association for a namespace/account pair
      # EKS permits only once -- all three of which fail at apply, not at plan. This module's own
      # usage example configured exactly that by hand until now, so it is the migration path rather
      # than a hypothetical. A variable validation cannot see a second variable, hence a
      # precondition; with count = 0 it correctly does not fire when the feature is off.
      condition = alltrue([
        for c in var.additional_pod_identity_configs :
        c.name != "filetask-objectstore" && !(
          c.namespace == var.filetask_objectstore.namespace &&
          c.serviceaccount_name == var.filetask_objectstore.serviceaccount_name
        )
      ])
      error_message = "filetask_objectstore is enabled, so drop the additional_pod_identity_configs entry that duplicates it: one named \"filetask-objectstore\", or one binding ${var.filetask_objectstore.namespace}/${var.filetask_objectstore.serviceaccount_name}."
    }
  }
}

resource "aws_iam_role_policy_attachment" "filetask_objectstore" {
  count = local.filetask_enabled ? 1 : 0

  role       = aws_iam_role.filetask_objectstore[0].name
  policy_arn = aws_iam_policy.filetask_objectstore[0].arn
}

resource "aws_eks_pod_identity_association" "filetask_objectstore" {
  count = local.filetask_enabled ? 1 : 0

  cluster_name    = local.name_prefix
  namespace       = var.filetask_objectstore.namespace
  service_account = var.filetask_objectstore.serviceaccount_name
  role_arn        = aws_iam_role.filetask_objectstore[0].arn
}
