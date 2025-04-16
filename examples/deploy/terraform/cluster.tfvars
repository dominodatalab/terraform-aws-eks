
irsa_policies = [{
  name                = "aws-efs-csi-driver-controller"
  namespace           = "domino-platform"
  serviceaccount_name = "aws-efs-csi-driver-controller"
  # policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"ec2:DescribeAvailabilityZones\", \"ec2:DescribeInstances\", \"ec2:DescribeSnapshots\", \"ec2:DescribeTags\", \"ec2:DescribeVolumes\", \"ec2:DescribeVolumesModifications\" ], \"Resource\": \"*\" }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateSnapshot\", \"ec2:ModifyVolume\" ], \"Resource\": \"arn:aws:ec2:*:*:volume/*\" }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:AttachVolume\", \"ec2:DetachVolume\" ], \"Resource\": [\"arn:aws:ec2:*:*:volume/*\", \"arn:aws:ec2:*:*:instance/*\" ] }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateVolume\", \"ec2:EnableFastSnapshotRestores\" ], \"Resource\": \"arn:aws:ec2:*:*:snapshot/*\" }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateTags\" ], \"Resource\": [\"arn:aws:ec2:*:*:volume/*\", \"arn:aws:ec2:*:*:snapshot/*\" ], \"Condition\": {\"StringEquals\": {\"ec2:CreateAction\": [\"CreateVolume\", \"CreateSnapshot\" ] } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:DeleteTags\" ], \"Resource\": [\"arn:aws:ec2:*:*:volume/*\", \"arn:aws:ec2:*:*:snapshot/*\" ] }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateVolume\" ], \"Resource\": \"arn:aws:ec2:*:*:volume/*\", \"Condition\": {\"StringLike\": {\"aws:RequestTag/ebs.csi.aws.com/cluster\": \"true\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateVolume\" ], \"Resource\": \"arn:aws:ec2:*:*:volume/*\", \"Condition\": {\"StringLike\": {\"aws:RequestTag/CSIVolumeName\": \"*\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:DeleteVolume\" ], \"Resource\": \"arn:aws:ec2:*:*:volume/*\", \"Condition\": {\"StringLike\": {\"ec2:ResourceTag/ebs.csi.aws.com/cluster\": \"true\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:DeleteVolume\" ], \"Resource\": \"arn:aws:ec2:*:*:volume/*\", \"Condition\": {\"StringLike\": {\"ec2:ResourceTag/CSIVolumeName\": \"*\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:DeleteVolume\" ], \"Resource\": \"arn:aws:ec2:*:*:volume/*\", \"Condition\": {\"StringLike\": {\"ec2:ResourceTag/kubernetes.io/created-for/pvc/name\": \"*\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateSnapshot\" ], \"Resource\": \"arn:aws:ec2:*:*:snapshot/*\", \"Condition\": {\"StringLike\": {\"aws:RequestTag/CSIVolumeSnapshotName\": \"*\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:CreateSnapshot\" ], \"Resource\": \"arn:aws:ec2:*:*:snapshot/*\", \"Condition\": {\"StringLike\": {\"aws:RequestTag/ebs.csi.aws.com/cluster\": \"true\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:DeleteSnapshot\" ], \"Resource\": \"arn:aws:ec2:*:*:snapshot/*\", \"Condition\": {\"StringLike\": {\"ec2:ResourceTag/CSIVolumeSnapshotName\": \"*\" } } }, {\"Effect\": \"Allow\", \"Action\": [\"ec2:DeleteSnapshot\" ], \"Resource\": \"arn:aws:ec2:*:*:snapshot/*\", \"Condition\": {\"StringLike\": {\"ec2:ResourceTag/ebs.csi.aws.com/cluster\": \"true\" } } } ] }"
  },
  {
    name                = "aws-ebs-csi-driver-controller"
    namespace           = "domino-platform"
    serviceaccount_name = "aws-ebs-csi-driver-controller"
    # policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"elasticfilesystem:DescribeAccessPoints\", \"elasticfilesystem:DescribeFileSystems\" ], \"Resource\": \"*\" }, {\"Effect\": \"Allow\", \"Action\": [\"elasticfilesystem:CreateAccessPoint\" ], \"Resource\": \"*\", \"Condition\": {\"StringLike\": {\"aws:RequestTag/efs.csi.aws.com/cluster\": \"true\" } } }, {\"Effect\": \"Allow\", \"Action\": \"elasticfilesystem:DeleteAccessPoint\", \"Resource\": \"*\", \"Condition\": {\"StringEquals\": {\"aws:ResourceTag/efs.csi.aws.com/cluster\": \"true\" } } } ]}"

  },

  {

    name                = "cluster-autoscaler"
    namespace           = "domino-platform"
    serviceaccount_name = "cluster-autoscaler"
    pod_identity        = true
    #     policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"autoscaling:DescribeAutoScalingGroups\", \"autoscaling:DescribeAutoScalingInstances\", \"autoscaling:DescribeLaunchConfigurations\", \"autoscaling:DescribeScalingActivities\", \"ec2:DescribeInstanceTypes\", \"ec2:DescribeLaunchTemplateVersions\" ], \"Resource\": [\"*\" ] }, {\"Effect\": \"Allow\", \"Action\": [\"autoscaling:SetDesiredCapacity\", \"autoscaling:TerminateInstanceInAutoScalingGroup\" ], \"Resource\": [\"*\" ] } ] }"

  }
]
