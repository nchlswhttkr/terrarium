data "vault_kv_secret_v2" "terrarium" {
  mount = "kv"
  name  = "buildkite/terrarium"
}

resource "aws_ssm_parameter" "tailscale_authentication_key" {
  name  = "/terrarium/tailscale-authentication-key"
  type  = "SecureString"
  value = data.vault_kv_secret_v2.terrarium.data.tailscale_authentication_key
}
