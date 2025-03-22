# Migrating from Managed Node Groups to Karpenter

This guide outlines the steps required to migrate from EKS managed node groups to Karpenter for node provisioning.

## Prerequisites

- Access to the EKS cluster.
- `kubectl` configured to access your cluster.
- `aws` cli installed.
- `envsubst` installed.[optional]
- `terraform` installed.
- AWS cli credentials.
- Understanding of your current node group configuration.
- Familiarity with Karpenter's [concepts](https://karpenter.sh/v1.0/concepts/).

## Migration Steps

### Overview of the migration process from EKS managed node groups to Karpenter:

1. Create Karpenter EKS Managed Node Groups
   - Karpenter itself will run in an EKS Managed Node Group

2. Provision Karpenter Infrastructure

3. Create Karpenter configuration

4. Verify Karpenter Functionality

5.  Move workloads to Karpenter-managed nodes

6. Verify all workloads are running properly

7. Remove Managed Node Groups


### 1. Create Karpenter Node Groups

Create the Karpenter node groups. Make sure you read the text below regarding setting `karpenter_node_groups.karpenter.availability_zone_ids` :


#### :warning: When `default_node_groups` and `additional_node_groups` are not defined (which will happen later when the migration to karpenter completes), the `availability_zone_ids` in `karpenter_node_groups` exclusively determine four things:

1. Which availability zones will have supporting network infrastructure (such as subnets and route tables) created.
2. Which subnets are used by the eks karpenter managed nodegroup to run karpenter itself.
3. Which subnets will karpenter use to provision its nodes.
4. Which subnets are used by the EKS cluster itself.

**IMPORTANT**: At a minimum, you must include all availability zone IDs corresponding to the subnets used by the EKS cluster. Modifying the EKS cluster's subnets after the cluster is created is not supported by this module.

Any AZ not listed will lack the necessary resources for Karpenter to provision instances and existing resources in those AZs may be deleted.

#### Therefore, if you want to preserve all existing subnets, route tables, and related infrastructure, ensure that `karpenter_node_groups.karpenter.availability_zone_ids` includes the set of all AZs previously used by `default_node_groups` and `additional_node_groups`.


1. Add the following to the infra.tfvars and nodes.tfvars
```hcl
# Consult the karpenter_node_groups variable for additional options.
karpenter_node_groups = {
  karpenter = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
    single_nodegroup = true
  }
}
```

1. Add the following to the cluster.tfvars
```hcl
Consult the karpenter variable for additional options.
karpenter = {
  enabled = true
}
```

### 2. Provision Karpenter Infrastructure

1. Verify the Terraform changes:
   ```bash
   ./tf.sh all plan
   ```

2. Apply the Terraform changes:
   ```bash
   ./tf.sh all apply
   ```

3. Verify Karpenter installation:
   ```bash
   kubectl get pods -n karpenter
   ```

### 3. Configure Karpenter Node Classes and Node Pools

1. Copy the `examples/karpenter` folder (this directory) onto your deployment directory.

2. Update the node classes in `examples/karpenter/ec2nodeclasses/`:
   1. You can run the following if you have `envsubst` installed:
   ```bash
    export EKS_NODES_ROLE_NAME=$(./tf.sh cluster output_json eks | jq -r '.eks.value.nodes.roles[0].name')
    export EKS_CLUSTER_NAME=$(./tf.sh cluster output_json eks | jq -r '.eks.value.cluster.specs.name')
    export AWS_REGION=$(./tf.sh cluster output_json eks | jq -r '.infra.value.region') ## This will be used later when scaling down the ASGs

    for nc in karpenter/ec2nodeclasses/*yaml
    do
      cat $nc | envsubst > $nc.tmp && mv $nc.tmp $nc
    done
   ```
   2. Or do it manually
   - Update the role to match your EKS node role. Get value: `./tf.sh cluster output_json eks | jq '.eks.value.nodes.roles[0].name'`
   - Update security group and subnet selectors to match your cluster. Should be the `<cluster_name>`. Get value: `./tf.sh cluster output_json eks | jq '.eks.value.cluster.specs.name'`
   3. Verify the configuration for all the `ec2nodeclasses` and `nodepools`.

3. :warning: Update the AMI selector in the nodepools. `al2023@latest` is not recommended for production environments. See karpenter docs [managing-amis](https://karpenter.sh/docs/tasks/managing-amis).

4. Update the node pools in `examples/karpenter/nodepools/`:
   - Match the instance types with your current node groups
   - Configure capacity requirements.
   - Most likely you will have `additional_node_groups`, you will need to create a <nodepool>.yaml for each. most likely it will just be an exact copy of compute/gpu with a different instance type(s)
   - **[OPTIONAL]** You dont necessarily have to set the `instance_types`, see karpenter docs for additional information on how to configure [nodepools](https://karpenter.sh/docs/concepts/nodepools/).

5. Apply the Karpenter configurations:
   ```bash
   bash -c karpenter/create-karpenter-configs.sh
   ```

### 5. Scale down Cluster autoscaler
Scale down autoscaler so to avoid collision with karpenter. This is temporary while the nodes are being migrated.

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

  1. Ensure the `ec2nodeclasses` and `nodepools` are `Ready`

  ```bash
    NAME                  READY   AGE
    domino-eks-compute    True    31s
    domino-eks-gpu        True    29s
    domino-eks-platform   True    27s

    NAME       NODECLASS             NODES   READY   AGE
    compute    domino-eks-compute    1       True    6m1s
    gpu        domino-eks-gpu        0       True    5m59s
    platform   domino-eks-platform   1       True    5m57s
  ```



### 6. Migrate Nodes

1. Get the existing(not kaperter) autoscaling groups(Adjust the filter below if necessary):

   ```
    aws autoscaling describe-auto-scaling-groups \
    --query "AutoScalingGroups[?contains(Tags[?Key=='eks:cluster-name'].Value, \`${EKS_CLUSTER_NAME}\`) && !contains(AutoScalingGroupName, 'eks-karpenter')].AutoScalingGroupName"
   ```

   Example output:
   ```
   [
       "eks-compute-mycluster-private-us-west-2a-9ccaf9a3-d83c-0ff5-37ef-ab3a1ae927e0",
       "eks-gpu-mycluster-private-us-west-2b-98caf9a3-d83c-bd6d-332e-837e8a60e3dd",
       "eks-other_az-mycluster-private-us-west-2c-34caf9a3-d83a-3665-56e3-7c5483774347",
       "eks-platform-mycluster-private-us-west-2b-1ccaf9a3-d83a-a2df-0dfe-92ac09f8d5f6"
   ]
   ```

2. Scale down ASGS. :warning: Make sure you do not scale down the `karpenter` node_group.

   1. You can scale down one at a time

   ```
   aws autoscaling update-auto-scaling-group --auto-scaling-group-name eks-other_az-mycluster-private-us-west-2c-34caf9a3-d83a-3665-56e3-7c5483774347 --max-size 0 --min-size 0 --desired-capacity 0
   ```

   2. Or, Scale down all ASGs at once:

  ```bash
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

4. Verify workloads are running and able to be scheduled on karpenter's provisioned nodes.
  ```
  kubectl get pods -A
  ```

### 7. Complete Migration

After all workloads are running on Karpenter's provisioned nodes you can  remove the `default_node_groups` and `additional_node_groups`:

1. Set `default_node_groups` and `additional_node_groups` to `null` in `nodes.tfvars` and `infra.tfvars`:

   ```hcl
   default_node_groups    = null
   additional_node_groups = null
   ```

2. Apply the changes:
:warning: When default_node_groups and additional_node_groups are deleted. We need to apply the changes in the `nodes` component first in  order to avoid the infra and cluster components from removing resources needed for the graceful deletion of the `managed node_groups`. Carefully inspect each of the plans before applying.

   ```bash
   ./tf.sh nodes plan
   ./tf.sh nodes apply

   ./tf.sh all plan
   ./tf.sh all apply
   ```

3. Scale up the cluster autoscaler
Cluster autoscaler will only manage the node_group where karpenter runs. The rest of the workloads will be handled with karpenter.

```bash
kubectl scale deployments/cluster-autoscaler --replicas=1 -n domino-platform
```

4. At this point all managed nodegroups have been removed, except for the karpenter nodegroup which houses karpenter itself. Existing workloads are being scheduled via karpenter.
