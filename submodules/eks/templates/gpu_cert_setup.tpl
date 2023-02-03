MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

!/bin/bash
set -ex
EKS_CONTAINERD_CFG="/etc/eks/containerd/containerd-config.toml"
if [ -n "$(egrep 'plugins\.cri\.containerd\.runtimes\.nvidia' $EKS_CONTAINERD_CFG)" ]; then
    sed -i 's/plugins\."io.containerd.grpc.v1.cri"\.registry/plugins.cri.registry/' $EKS_CONTAINERD_CFG
fi


--==MYBOUNDARY==--\
