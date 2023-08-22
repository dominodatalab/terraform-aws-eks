# Terraform Multi-Module Management

## Overview
The `tf.sh` script provides a convenient method to manage multiple Terraform configurations for various components of a system. The primary modules managed by this script include `infra`, `cluster`, and `nodes`. These components might represent different layers of an infrastructure deployment.

## Pre-requisites
* Ensure that `terraform` is installed and accessible in your path.
* Ensure that `jq`, a command-line JSON processor, is installed.

## Directory Structure
The script expects the following directory structure:
```
examples/deploy
├── README.md
├── meta.sh
├── set-mod-version.sh
├── terraform
│   ├── cluster
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── cluster.tfvars
│   ├── infra
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── infra.tfvars
│   ├── nodes
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── nodes.tfvars
└── tf.sh
```

* Each subdirectory under `terraform` (e.g., `infra`, `cluster`, `nodes`) should contain its respective Terraform configurations.
* Each component is expected to have a corresponding `.tfvars` file at the root directory. For instance, for the `infra` component, there should be an `infra.tfvars` in the root directory.
* Each of component's state and output(when the `output` command is invoked) is saved in the `terraform` directory:

```bash
└── examples/deploy/terraform
   ├── cluster.outputs
   ├── cluster.tfstate
   ├── infra.outputs
   ├── infra.tfstate
   ├── nodes.outputs
   └── nodes.tfstate
```
## Variables structure

The modular design of this Terraform setup allows for a streamlined flow of variable values across different stages of your infrastructure, from the foundational `infra` module up to the more specialized `nodes` module.


### Inter-module Variable Propagation

1. **From `infra` to `cluster`**:
   * The `infra` module is where most foundational variables are defined. Once provisioned, these variable values can be consumed by the `cluster` module using Terraform's [remote state data source](https://www.terraform.io/docs/language/state/remote-state-data.html).

2. **From both `infra` and `cluster` to `nodes`**:
   * The `nodes` module consumes variable values from both the `infra` and `cluster` modules. This is achieved by accessing their respective remote states.

### infra.tfvars
You can find examples in the examples/tfvars directory. This file accommodates all variables defined in modules/infra.

### cluster.tfvars
This file provides the capability to override the k8s_version variable, aiding in Kubernetes upgrades.

### nodes.tfvars
This file allows you to override two variables: default_node_groups and additional_node_groups, making it easier to update node groups.

### Overriding Variables for Kubernetes Upgrades

The ability to upgrade Kubernetes without affecting other infrastructure components is crucial for maintainability:

```bash
.
├── README.md
├── cluster.tfvars
├── infra.tfvars
├── nodes.tfvars
├── terraform
│   ├── cluster
│   ├── infra
│   └── nodes
└── tf.sh
```

* The `cluster` module accepts a variable named `k8s_version` via the `cluster.tfvars`.
* While the initial value of `k8s_version` comes from the `infra` module, you have the flexibility to overwrite it in the `cluster` module via the the `cluster.tfvars`. This facilitates Kubernetes version upgrades without making changes to the underlying infrastructure set up by the `infra` module.

### Enhancing Flexibility in Node Configurations

For node configurations and upgrades, the design follows a similar pattern:

* The `nodes` module allows you to override the default node configurations (`default_node_groups`) and any additional node configurations (`additional_node_groups`).
* This is done using the `merge` function, ensuring you can easily add or modify node groups as required.
* In scenarios where only the node pool requires an update, you can simply modify the `nodes.tfvars` and run `./tf.sh apply nodes`. This avoids the need to reapply the `infra` or `cluster` modules, streamlining node management.

With this structure, the infrastructure maintains a clear hierarchy of variable propagation, ensuring ease of use, flexibility, and minimal disruptions during updates and upgrades.


## Usage

To use the script, invoke it with the desired command and component:

```bash
./tf.sh <command> <component>
```

* **command**: Supported commands include:
  * init: Initializes the Terraform configurations.
  * plan: Shows the execution plan of Terraform.
  * apply: Applies the Terraform configurations.
  * destroy: Destroys the Terraform resources.
  * output: Shows the output values of your configurations.
  * refresh: Refreshes the Terraform state file.
* **component**: The component you wish to apply the command on. Supported components are `infra`, `cluster`, `nodes`, and `all`. Using `all` will apply the command on all components.


## Examples

* To preview the execution plan of the cluster:

```bash
./tf.sh plan cluster
```

* To create all components:

```bash
./tf.sh apply all
```

* To destroy all components:

```bash
./tf.sh destroy all
```

## Common Operations

For some frequently performed operations, follow the steps outlined below:

### Initial install
See the repo's [README](../../README.md#bootstrap-module) for how to bootstrap the module.

### Updating the modules' version
See `README` [Update modules version](../../README.md#update-modules-version)

### K8s Upgrade

#### Kubernetes Upgrade:

1. Update the `k8s-version` variable in the `cluster.tfvars` file.
2. Update cluster:
   1. Plan and review the changes:
      ```bash
      ./tf.sh plan cluster
      ```
   2. Apply the changes:
      ```bash
      ./tf.sh apply cluster
      ```
3. Update nodes:
   1. Plan and review the changes:
      ```bash
      ./tf.sh plan nodes
      ```
   2. Apply the changes:
      ```bash
      ./tf.sh apply nodes
      ```

#### Nodes Upgrade:
In order to just update the nodes to the latest AMI for the existing version.

1. Update nodes:
   1. Plan and review the changes:
      ```bash
      ./tf.sh plan nodes
      ```
   2. Apply the changes:
      ```bash
      ./tf.sh apply nodes
      ```
