#!/bin/bash

set -e

if ! command -v iptables > /dev/null 2>&1; then
  if command -v dnf > /dev/null 2>&1; then
    dnf install -y iptables
  fi
fi

token="$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 300' http://169.254.169.254/latest/api/token)"
outbound_mac="$(curl -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/mac)"
outbound_eni_id="$(curl -H "X-aws-ec2-metadata-token: $token" "http://169.254.169.254/latest/meta-data/network/interfaces/macs/$outbound_mac/interface-id")"
nat_interface=$(ip link show dev "$outbound_eni_id" | head -n 1 | awk '{print $2}' | sed s/://g )

sysctl -q -w net.ipv4.ip_forward=1
find /proc/sys/net/ipv4/conf/ -name rp_filter | while read -r i; do echo 0 > "$i"; done
iptables -t nat -F
iptables -t nat -A POSTROUTING -o "$nat_interface" -j MASQUERADE
