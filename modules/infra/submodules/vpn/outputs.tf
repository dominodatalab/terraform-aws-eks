output "vpn_connections" {
  description = "List of VPN connections information"
  sensitive   = true
  value = [
    for k, v in aws_vpn_connection.this : {
      name = k
      ip_sec_tunnel_1 = {
        address       = v.tunnel1_address
        preshared_key = v.tunnel1_preshared_key
      }
      ip_sec_tunnel_2 = {
        address       = v.tunnel2_address
        preshared_key = v.tunnel2_preshared_key
      }
    }
  ]
}
