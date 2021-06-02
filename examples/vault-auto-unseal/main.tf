resource "kubernetes_namespace" "vault1" {
  metadata {
    name = "vault1"
  }
}
resource "kubernetes_namespace" "vault2" {
  metadata {
    name = "vault2"
  }
}

resource "kubectl_manifest" "vault1_certificate" {
  yaml_body = <<EOT
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vault
  namespace: ${kubernetes_namespace.vault1.metadata[0].name}
spec:
  secretName: vault-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
  - vault1.example.com
EOT
}

resource "kubectl_manifest" "vault2_certificate" {
  yaml_body = <<EOT
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vault
  namespace: ${kubernetes_namespace.vault2.metadata[0].name}
spec:
  secretName: vault-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
  - vault2.example.com
EOT
}

module "vault1" {
  source                            = "github.com/nimbolus/tf-vault/vault-consul"
  release_name                      = "vault1"
  namespace                         = kubernetes_namespace.vault.metadata[0].name
  vault_domain                      = yamldecode(kubectl_manifest.vault1_certificate.yaml_body_parsed)["spec"]["dnsNames"][0]
  consul_address                    = "consul.example.com"
  auto_unseal_enable                = true
  auto_unseal_vault_service_address = "https://vault2.example.com"
  auto_unseal_vault_mount_path      = "vault-transit"
  auto_unseal_vault_role            = "vault-unseal"
  tls_secret_name                   = yamldecode(kubectl_manifest.vault1_certificate.yaml_body_parsed)["spec"]["secretName"]
  ingress_ssl_passthrough_enable    = true
}

module "vault2" {
  source                            = "github.com/nimbolus/tf-vault/vault-consul"
  release_name                      = "vault2"
  namespace                         = kubernetes_namespace.vault.metadata[0].name
  vault_domain                      = yamldecode(kubectl_manifest.vault2_certificate.yaml_body_parsed)["spec"]["dnsNames"][0]
  consul_address                    = "consul.example.com"
  auto_unseal_enable                = true
  auto_unseal_vault_service_address = "https://vault1.example.com"
  auto_unseal_vault_mount_path      = "vault-transit"
  auto_unseal_vault_role            = "vault-unseal"
  tls_secret_name                   = yamldecode(kubectl_manifest.vault2_certificate.yaml_body_parsed)["spec"]["secretName"]
  ingress_ssl_passthrough_enable    = true
}

provider "vault" {
  alias = "vault1"
  address = module.vault1.vault_address
  # set VAULT_TOKEN in environment
}

provider "vault" {
  alias = "vault2"
  address = module.vault2.vault_address
  # set VAULT_TOKEN in environment
}

module "vault_transit1" {
  depends_on = [module.vault]
  providers = {
    vault = vault.vault1
   }
  source    = "github.com/nimbolus/tf-vault/vault-transit"
  name      = "vault2"
  namespace = "vault2"
}

module "vault_transit2" {
  depends_on = [module.vault]
  providers = {
    vault = vault.vault2
   }
  source    = "github.com/nimbolus/tf-vault/vault-transit"
  name      = "vault1"
  namespace = "vault1"
}
