data "vault_kv_secret_v2" "tailscale" {
  mount = "kv"
  name  = "terrarium/tailscale"
}

resource "aws_ssm_parameter" "tailscale_authentication_key" {
  name  = "/terrarium/tailscale-authentication-key"
  type  = "SecureString"
  value = data.vault_kv_secret_v2.tailscale.data.authentication_key
}
