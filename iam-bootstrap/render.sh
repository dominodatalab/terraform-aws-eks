#!/bin/bash

export deploy_id=example
export account_id=1234567890

echo "Rendering bootstrap-*.json to bootstrap-render-*.json..."
cat bootstrap-0.json | envsubst > bootstrap-rendered-0.json
cat bootstrap-1.json | envsubst > bootstrap-rendered-1.json
