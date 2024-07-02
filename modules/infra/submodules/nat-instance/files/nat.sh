#!/bin/bash

set -e

sysctl -q -w net.ipv4.ip_forward=1
find /proc/sys/net/ipv4/conf/ -name rp_filter | while read -r i; do echo 0 > "$i"; done
iptables -t nat -F
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
