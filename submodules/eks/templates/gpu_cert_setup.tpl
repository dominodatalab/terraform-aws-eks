MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

!/bin/bash
set -ex
EKS_CONTAINERD_CFG="/etc/eks/containerd/containerd-config.toml"
if [ -z "$(egrep 'certs\.d' $EKS_CONTAINERD_CFG)" ]; then
    if [ -n "$(egrep 'plugins\.cri\.containerd\.runtimes\.nvidia' $EKS_CONTAINERD_CFG)" ]; then
        printf '\n\n[plugins.cri.registry]\nconfig_path = "/etc/containerd/certs.d:/etc/docker/certs.d"\n' >> $EKS_CONTAINERD_CFG
    fi
fi

--==MYBOUNDARY==--\
