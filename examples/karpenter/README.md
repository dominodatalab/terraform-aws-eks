## Karpenter Configuration Script

This directory contains the configuration files and scripts for setting up Karpenter in your EKS cluster.

## Prerequisites

- `kubectl` installed and configured with access to your EKS cluster
- `envsubst` installed, needed for the `render` feature

## Directory Structure

```
karpenter/templates
├── ec2nodeclasses/               # Contains EC2NodeClass configurations
├── nodepools/                    # Contains NodePool configurations
└── karpenter-configs.sh   # Script to apply configurations
```

## Usage

1.  Render templates
   ```bash
   ./karpenter-configs.sh render
   ```

2.  Apply all karpenter configuration files
   ```bash
   ./karpenter-configs.sh apply
   ```

## NodePool Configurations

### Platform Jobs NodePool

The `platform-jobs` NodePool is designed to isolate job workloads from the platform infrastructure nodes to prevent Karpenter thrashing and node reshuffling.

**Purpose:**
- Prevents platform nodes from being disrupted by short-lived job workloads
- Avoids scenarios where a single job triggers new platform node creation and subsequent consolidation
- Provides dedicated, elastic capacity for platform job execution

**Configuration Highlights:**
- **Fast consolidation**: `consolidateAfter: 5m` (vs 35m for platform nodes)
- **Conservative policy**: `WhenEmpty` only (won't disrupt running jobs)
- **Flexible instance selection**: Supports `m6a`, `m6i`, and `m7i-flex` families with 2 or 4 vCPUs

**Domino Configuration:**

To enable Domino platform components to use this NodePool, add the following to your `domino.yaml`:

```yaml
platform_jobs_node_selectors:
  dominodatalab.com/node-pool: platform-jobs
```

This configuration enables a gradual migration of Domino jobs to dedicated job nodes. Over time, jobs will be moved to use the `platform-jobs` NodePool rather than competing for resources on tightly-packed platform infrastructure nodes.

## What the Script Does

The script performs the following checks and actions:

1. Verifies that required template directory exists and contain yaml files (`templates/ec2nodeclasses/` and `templates/nodepools/`) exist
2. Creates `ec2nodeclasses/` and `nodepools/` directories
4. Renders ec2nodeclasses and nodepools
   1. It queries aws for the latest AL2023 AMI and populates the `ec2nodeclasses`.
   2. Sets the IAM Role to be used by Karpenter nodes.
   3. Sets the label which dictates which subnets and security groups are to be discovered/leveraged by karpenter.
5. Applies ec2nodeclass configurations
6. Applies nodepool configurations
