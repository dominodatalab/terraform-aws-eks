data "aws_iam_policy_document" "filetask_mount" {
  count = var.filetask_objectstore_mount_enabled ? 1 : 0

  statement {
    sid    = "MountS3Files"
    effect = "Allow"
    actions = [
      "s3files:ClientMount",
      "s3files:ClientWrite",
      "s3files:ClientRootAccess",
      "s3files:GetFileSystem",
    ]
    # The mount is performed by the EFS CSI driver, which authenticates as the node, so this
    # grant belongs on the node role rather than a pod identity association.
    resources = ["arn:${data.aws_partition.current.partition}:s3files:*:${local.aws_account_id}:file-system/*"]
  }
}

resource "aws_iam_policy" "filetask_mount" {
  count = var.filetask_objectstore_mount_enabled ? 1 : 0

  name   = "${var.deploy_id}-filetask-mount"
  path   = "/"
  policy = data.aws_iam_policy_document.filetask_mount[0].json
}

resource "aws_iam_role_policy_attachment" "filetask_mount" {
  count = var.filetask_objectstore_mount_enabled ? 1 : 0

  role       = aws_iam_role.eks_nodes.name
  policy_arn = aws_iam_policy.filetask_mount[0].arn
}
