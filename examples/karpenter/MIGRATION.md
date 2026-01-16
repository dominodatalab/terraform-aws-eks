# Migrating from Managed Node Groups to Karpenter

This guide outlines the steps required to migrate from EKS managed node groups to Karpenter for node provisioning.

## Prerequisites

- Infrastructure provisioned using latest [released](https://github.com/dominodatalab/terraform-aws-eks/releases) version of this module before attempting to migrate to karpenter.
- Access to the EKS cluster.
- `kubectl` configured to access your cluster.
- `aws` cli installed.
- `envsubst` installed.[optional]
- `terraform` installed.
- AWS cli credentials.
- Understanding of your current node group configuration.
- Familiarity with Karpenter's [concepts](https://karpenter.sh/v1.0/concepts/).

## Migration Steps

### Overview

The migration process from EKS managed node groups to Karpenter consists of the following steps:

1. Create Karpenter EKS Managed Node Groups
   - Karpenter itself will run in an EKS Managed Node Group
2. Provision Karpenter Infrastructure
3. Create Karpenter configuration
4. Verify Karpenter Functionality
5. Move workloads to Karpenter-managed nodes
6. Verify all workloads are running properly
7. Remove Managed Node Groups

### 1. Create System Node Groups

Create the system node groups. Make sure you read the text below regarding setting `system_node_group.system.availability_zone_ids`.

#### Important Considerations

When `default_node_groups` and `additional_node_groups` are not defined (which will happen later when the migration to karpenter completes), the `availability_zone_ids` in `system_node_group` exclusively determine four things:

1. Which availability zones will have supporting network infrastructure (such as subnets and route tables) created.
2. Which subnets are used by the eks system managed nodegroup to run karpenter itself.
3. Which subnets will karpenter use to provision its nodes.
4. Which subnets are used by the EKS cluster itself.

**IMPORTANT**: **At a minimum, you must include all availability zone IDs corresponding to the subnets used by the EKS cluster**. Modifying the EKS cluster's subnets after the cluster is created is not supported by this module.

For example, with the following current configuration:

```hcl
default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1","usw2-az2"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az1","usw2-az3"]
  }
  platform = {
    availability_zone_ids= ["usw2-az2"]
  }
}

additional_node_groups = {
  other_az = {
    availability_zone_ids = ["usw2-az4"]
  }
}
```

We recommend including all AZs:

```hcl
system_node_group = {
  system = {
    availability_zone_ids = ["usw2-az1", "usw2-az2", "usw2-az3", "usw2-az4"]
    single_nodegroup = true
  }
}
```

Any AZ not listed will lack the necessary resources for Karpenter to provision instances and existing resources in those AZs may be deleted.

Given that karpenter itself is stateless, we set the `single_nodegroup` in order to just create one node_group with all the included subnets for the `availability_zone_ids`. If you prefer to have a node_group per zone, do not set this, set `single_nodegroup = false` or omit entirely.

#### Implementation Steps

1. Add the following to the infra.tfvars and nodes.tfvars:

```hcl
# Consult the system_node_group variable for additional options.
system_node_group = {
  system = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
    single_nodegroup = true
  }
}
```

2. Add the following to the cluster.tfvars:

```hcl
# Consult the karpenter variable for additional options.
karpenter = {
  enabled = true
}
```

### 2. Provision Karpenter Infrastructure

1. Verify the Terraform changes:

```bash
./tf.sh all plan
```
- Expected changes:

  :warning: There should not be any resource being destroyed nor replaced.

  - `infra`: No changes expected if the `system_node_group.system.availability_zone_ids` are already in use by by existing node_groups. Otherwise it will create the network resources necessary in the new `availability_zone_ids`
  - `cluster`:
    - Creates:
      - `aws_iam_role_policy`
      - `aws_iam_role`
      - `aws_eks_pod_identity_association`
  - `nodes`:
    - Creates:
      - `module.nodes.aws_ec2_tag.karpenter` - Tags Subnets and SecurityGroups to be used by Karpenter. These tags are later interpolated in the `ec2nodeclasses`.
      - Only private subnets corresponding to the `availability_zone_ids` specified for the karpenter node_group will be tagged.
      - `karpenter` nodegroup(s)
      - `module.nodes.terraform_data.karpenter_setup`
        - Installs and Updates Karpenter.
      - `module.nodes.terraform_data.delete_karpenter_instances`
        - This resource uses an on `destroy` provisioner to terminate karpenter instances when the module is being destroyed.



1. Apply the Terraform changes:

```bash
./tf.sh all apply
```

3. Verify Karpenter installation:

```bash
kubectl get pods -n karpenter
```

### 3. Configure Karpenter Node Classes and Node Pools.

#### `al2023` ami alias
When using the default AL2023 AMI via the `al2023` alias, you'll need at least two separate EC2NodeClasses:

1. `domino-eks-platform` (100Gi EBS volume)
2. `domino-eks-compute` Compute/GPU/Neuron node pools (1000Gi EBS volume)

While these node types share the same base AMI configuration, they require separate EC2NodeClasses due to their different EBS volume requirements. The compute EC2NodeClass can be used for regular compute, GPU, and Neuron workloads - Karpenter will automatically select the appropriate instance type based on the workload requirements.

In this example, we create 4 distinct EC2NodeClasses (platform, compute, gpu, neuron) all using the same `al2023` AMI alias. While we could consolidate some of these EC2NodeClasses since they share identical configurations (e.g. gpu and compute both use 1000Gi volumes), we maintain them as separate entities for:

1. Clear mapping between NodePools and EC2NodeClasses
2. Easier to handle future AMI changes per node type
3. Simpler AMI updates with isolated changes


If you have additional node groups with different infrastructure requirements (e.g., different EBS volumes, instance types, etc.), you'll need to create corresponding EC2NodeClasses for those as well.

#### Custom AMI
Unlike with the `al2023` AMI alias where consolidating EC2NodeClasses is possible, when using custom AMIs you MUST create separate EC2NodeClasses for each AMI variant:

- Standard AMI - Used by platform and compute nodes, requires two separate EC2NodeClasses:
  - Platform nodes (100Gi EBS volume)
  - Compute nodes (1000Gi EBS volume)
- Neuron AMI - Required separate EC2NodeClass for Trainium/Inferentia workloads
- GPU AMI - Required separate EC2NodeClass for GPU workloads

This separation is mandatory because each node type requires its own specialized AMI with different drivers and configurations. Even when nodes share the same base AMI (like platform and compute using the standard AMI), you still need separate EC2NodeClasses if they have different infrastructure requirements like:
- EBS volume sizes
- Instance types

If you do not wish to use the script to create and apply the `ec2nodeclasses` and `nodepools`, you can skip to [Verify Karpenter Setup](#4-verify-karpenter-setup)

1. Copy the `examples/karpenter` folder (this directory) onto your deployment directory.

2. Render the Karpenter configurations:
   We have created the `karpenter-configs.sh` to assist in creating and applying the karpenter configs.
   You can create these manually and place them in the `karpenter/ec2nodeclasses` and `karpenter/nodepools` directories and just use the script to apply.

   :warning: Ensure you have AWS cli access on your terminal before running the next step

   1. The `render` parameter will populate the following Variables in the `ec2nodeclasses`:
      - `EKS_NODES_ROLE_NAME`
      - `EKS_CLUSTER_NAME`
      - `AL2023_AMI_ALIAS` Dynamically obtained from aws.

      Command:
      ```bash
      ./karpenter/karpenter-configs.sh render
      ```

   2. Inspect the rendered files in the `karpenter/ec2nodeclasses`:
      - Make sure each `ec2nodeclass` meets your capacity requirements (i.e ebs).
      - If you want to use a different AMI, keep in mind that using `latest` with an alias, i.e `al2023@latest` is not recommended for production environments, instead use a pinned version like `al2023@v20250317`.
      - If you want to use a CUSTOM AMI check the Karpenter [docs](https://karpenter.sh/docs/tasks/managing-amis/#pinning-amis) for additional options.
      - [Optional] If you desire you can add new ec2nodeclasses to the `karpenter/templates/ec2nodeclasses` with the same variables as existing(i.e `AL2023_AMI_ALIAS`) so that you can leverage the script for future AMI upgrades.

   3. Update the node pools in `karpenter/nodepools/`:
      - Match the instance types with your current node groups
      - Most likely you will have `additional_node_groups`, you will need to create a <nodepool>.yaml for each. most likely it will just be an exact copy of compute/gpu with a different instance type(s)
      - Make sure you match each nodepool's nodeclass (`spec.template.spec.nodeClassRef.name`) to the appropriate `ec2nodeclass`
      - **[OPTIONAL]** You dont necessarily have to set the `instance_types`, see karpenter [nodepools](https://karpenter.sh/docs/concepts/nodepools/) docs for additional information on how to configure.

:warning: Ensure you are authenticated with the cluster in order to run `kubectl` commands, before performing the next step.

3. Apply the Karpenter configurations:

```bash
./karpenter/karpenter-configs.sh apply
```


### 4. Verify Karpenter Setup

1. Check Karpenter components:

```bash
kubectl get pods -n karpenter
kubectl get ec2nodeclass
kubectl get nodepool
```

2. Ensure the `ec2nodeclasses` and `nodepools` are `Ready`:

```bash
NAME                  READY   AGE
domino-eks-compute    True    31s
domino-eks-gpu        True    29s
domino-eks-platform   True    27s

NAME       NODECLASS             NODES   READY   AGE
compute    domino-eks-compute    0       True    6m1s
gpu        domino-eks-gpu        0       True    5m59s
platform   domino-eks-platform   0       True    5m57s
```

### 5. Scale down Cluster Autoscaler
Make sure all Karpenter configurations are applied and ready before proceeding with scaling down the cluster autoscaler. This ensures there is no disruption in node provisioning capabilities.

Scale down autoscaler to avoid collision with karpenter. This is temporary while the nodes are being migrated.

```bash
kubectl scale deployments/cluster-autoscaler --replicas=0 -n domino-platform

# verify that cas is not running
kubectl get pods -n domino-platform | grep autoscaler
```

### 5. Verify Karpenter Setup

1. Check Karpenter components:

```bash
kubectl get pods -n karpenter
kubectl get ec2nodeclass
kubectl get nodepool
```

2. Ensure the `ec2nodeclasses` and `nodepools` are `Ready`:

```bash
NAME                  READY   AGE
domino-eks-compute    True    31s
domino-eks-gpu        True    29s
domino-eks-platform   True    27s
domino-eks-neuron   True    32s

NAME       NODECLASS             NODES   READY   AGE
compute    domino-eks-compute    0       True    6m1s
gpu        domino-eks-gpu        0       True    5m59s
platform   domino-eks-platform   0       True    5m57s
trainium   domino-eks-platform   0       True    6m5s
```

### 6. Migrate Nodes

1. Get the existing (excluding the `karpenter` ASG) autoscaling groups (Adjust the filter below if necessary):

```bash
export EKS_CLUSTER_NAME=$(./tf.sh cluster output_json eks | jq -r '.eks.value.cluster.specs.name')
export AWS_REGION=$(./tf.sh cluster output_json eks | jq -r '.infra.value.region')
aws autoscaling describe-auto-scaling-groups \
--query "AutoScalingGroups[?contains(Tags[?Key=='eks:cluster-name'].Value, \`${EKS_CLUSTER_NAME}\`) && !contains(AutoScalingGroupName, 'eks-karpenter')].AutoScalingGroupName"
```

Example output:
```bash
[
    "eks-compute-mycluster-private-us-west-2a-9ccaf9a3-d83c-0ff5-37ef-ab3a1ae927e0",
    "eks-gpu-mycluster-private-us-west-2b-98caf9a3-d83c-bd6d-332e-837e8a60e3dd",
    "eks-other_az-mycluster-private-us-west-2c-34caf9a3-d83a-3665-56e3-7c5483774347",
    "eks-platform-mycluster-private-us-west-2b-1ccaf9a3-d83a-a2df-0dfe-92ac09f8d5f6"
]
```

2. Scale down ASGs. :warning: Make sure you do not scale down the `karpenter` node_group.

    1. You can scale down one at a time:

    ```bash
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name eks-other_az-mycluster-private-us-west-2c-34caf9a3-d83a-3665-56e3-7c5483774347 --max-size 0 --min-size 0 --desired-capacity 0
    ```

    2. Or, scale down all ASGs at once:

    ```bash
    export EKS_CLUSTER_NAME=$(./tf.sh cluster output_json eks | jq -r '.eks.value.cluster.specs.name')
    export AWS_REGION=$(./tf.sh cluster output_json eks | jq -r '.infra.value.region')
    for asg in $(aws autoscaling describe-auto-scaling-groups \
        --query "AutoScalingGroups[?contains(Tags[?Key=='eks:cluster-name'].Value, \`${EKS_CLUSTER_NAME}\`) && !contains(AutoScalingGroupName, 'eks-karpenter')].AutoScalingGroupName" \
        --output text); do
      echo "Scaling down ASG: $asg"
      aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name "$asg" \
        --max-size 0 --min-size 0 --desired-capacity 0
    done
    ```

3. Verify Karpenter nodes:

```bash
kubectl get nodes -o wide
kubectl get nodes -l 'karpenter.sh/nodepool'

# Shows the lifecycle of the karpenter nodes
kubectl get nodeclaim

# Check the karpenter logs
kubectl get pods -n karpenter
kubectl logs -n karpenter <karpenter-pod>
```

4. Verify workloads are running and able to be scheduled on karpenter's provisioned nodes:

```bash
kubectl get pods -A
```

### 7. Complete Migration

After all workloads are running on Karpenter's provisioned nodes, you can remove the `default_node_groups` and `additional_node_groups`:

1. Set `default_node_groups` and `additional_node_groups` to `null` in `nodes.tfvars` and `infra.tfvars`:

```hcl
default_node_groups    = null
additional_node_groups = null
```

2. Apply the changes:
   :warning: When default_node_groups and additional_node_groups are deleted, we need to apply the changes in the `nodes` component first in order to avoid the infra and cluster components from removing resources needed for the graceful deletion of the `managed node_groups`. Carefully inspect each of the plans before applying. Verify there are no subnet changes for the `module.eks.aws_eks_cluster.this` resource

```bash
./tf.sh nodes plan
```
  1. Expected changes:
     1. The following resources corresponding to the `default_node_groups` and `additional_node_groups` will be destroyed:
        1. `module.nodes.aws_autoscaling_group_tag.tag`
        2. `module.nodes.aws_eks_node_group.node_groups`
        3. `module.nodes.aws_launch_template.node_groups`

  2.  Once the plan has been reviewed, Apply:
  ```bash
  ./tf.sh nodes apply
  ```

  3. Reconcile all the components:
  ```bash
  ./tf.sh all plan
  ```

  If you configured the karpenter nodegroups' availability_zone_ids to contain all of the ones used by the `default_node_groups` and `additional_node_groups` there should be no resources  being  changed, replaced nor destroyed(only outputs are expected to change).

  1. Once ALL the plans have been reviewed, Apply:
  ```bash
  ./tf.sh all apply
  ```

1. Scale up the cluster autoscaler:
   Cluster autoscaler will only manage the node_group where karpenter runs. The rest of the workloads will be handled with karpenter.

```bash
kubectl scale deployments/cluster-autoscaler --replicas=1 -n domino-platform
```

4. At this point all managed nodegroups have been removed, except for the karpenter nodegroup which houses karpenter itself. Existing workloads are being scheduled via karpenter.
