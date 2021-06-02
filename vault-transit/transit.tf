resource "vault_mount" "transit" {
  path        = "${var.name}-transit"
  type        = "transit"
  description = "transit secret engine for auto unsealing"
}

resource "vault_transit_secret_backend_key" "auto_unseal" {
  backend = vault_mount.transit.path
  name    = var.transit_secret_name
  type    = var.transit_secret_type
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.kubernetes_auth_path
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  lifecycle {
    ignore_changes = [
      kubernetes_ca_cert
    ]
  }
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default"
}

resource "vault_policy" "vault_server" {
  name = "${var.name}-unseal"

  policy = <<-EOT
    path "${vault_mount.transit.path}/encrypt/${var.transit_secret_name}" {
      capabilities = ["update"]
    }
    path "${vault_mount.transit.path}/decrypt/${var.transit_secret_name}" {
      capabilities = ["update"]
    }
    path "*" {
        capabilities = ["create", "read", "update", "delete", "list"]
    }
    EOT
}

resource "vault_kubernetes_auth_backend_role" "vault_server" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "${var.name}-unseal"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = [var.namespace]
  token_policies                   = [vault_policy.vault_server.name]
}
