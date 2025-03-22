# Karpenter Configuration Script

This directory contains the configuration files and scripts for setting up Karpenter in your EKS cluster.

## Prerequisites

- `kubectl` installed and configured with access to your EKS cluster

## Directory Structure

```
karpenter/
├── nodeclasses/     # Contains EC2NodeClass configurations
├── nodepools/       # Contains NodePool configurations
└── create-karpenter-configs.sh  # Script to apply configurations
```

## Usage

1.  Run the script from the karpenter directory:
   ```bash
   ./create-karpenter-configs.sh
   ```

## What the Script Does

The script performs the following checks and actions:

1. Verifies that required directories (`nodeclasses/` and `nodepools/`) exist
2. Checks that both directories contain YAML files
3. Applies nodeclass configurations
4. Applies nodepool configurations

## Error Handling

The script will exit with an error message if:
- Required directories are missing
- No YAML files are found in the directories
- Any kubectl apply command fails
