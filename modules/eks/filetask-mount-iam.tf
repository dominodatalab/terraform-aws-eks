# S3 Files mount permission for Domino's dataset storage.
#
# Authorising a mount is a separate grant from reading the bucket behind it. The task identity
# reaches the bucket through the S3 API and lives in modules/pod-identity; the mount is performed by
# the EFS CSI driver, which authenticates as the node -- so that half belongs here, on the node role.
#
# Not bound to the driver's ServiceAccount: a Pod Identity association binds a ServiceAccount, so it
# would govern every volume that driver mounts, and on an EFS-backed cluster the same driver serves
# the Domino shared store. Attaching here is additive and cannot break a mount that already works.

data "aws_iam_policy_document" "filetask_mount" {
  count = var.filetask_objectstore_mount_enabled ? 1 : 0

  statement {
    sid    = "MountS3Files"
    effect = "Allow"
    # A measured minimum: GetMountTarget and ListMountTargets changed nothing, and dropping
    # GetFileSystem failed the mount. No `s3:` action belongs here -- the file system reaches its
    # bucket through its own service role, and object access on a role that every pod reaching IMDS
    # can assume would hand out dataset contents.
    actions = [
      "s3files:ClientMount",
      "s3files:ClientWrite",
      "s3files:ClientRootAccess",
      "s3files:GetFileSystem",
    ]
    # Not scoped to a file system id: the file systems are created outside this Terraform and
    # usually do not exist when the cluster is built.
    resources = ["arn:${data.aws_partition.current.partition}:s3files:*:*:file-system/*"]
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
