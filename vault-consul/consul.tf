# https://www.vaultproject.io/docs/configuration/storage/consul#acls
resource "consul_acl_policy" "vault" {
  name  = "${var.release_name}-vault"
  rules = <<-RULE
    {
      "key_prefix": {
        "${var.release_name}-vault/": {
          "policy": "write"
        }
      },
      "node_prefix": {
        "": {
          "policy": "write"
        }
      },
      "service": {
        "vault": {
          "policy": "write"
        }
      },
      "agent_prefix": {
        "": {
          "policy": "write"
        }
      },
      "session_prefix": {
        "": {
          "policy": "write"
        }
      }
    }
    RULE
}

resource "consul_acl_token" "vault" {
  description = "${var.release_name} vault server"
  policies    = [consul_acl_policy.vault.name]
  local       = true
}

data "consul_acl_token_secret_id" "vault" {
  accessor_id = consul_acl_token.vault.id
}
