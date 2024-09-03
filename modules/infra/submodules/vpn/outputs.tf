output "vpn_connection" {
  description = "VPN connection information"
  sensitive   = true
  value = {
    ip_sec_tunnel_1 = {
      address       = aws_vpn_connection.this.tunnel1_address
      preshared_key = nonsensitive(aws_vpn_connection.this.tunnel1_preshared_key)
    }
    ip_sec_tunnel_2 = {
      address       = aws_vpn_connection.this.tunnel2_address
      preshared_key = nonsensitive(aws_vpn_connection.this.tunnel2_preshared_key)
    }
  }
}
