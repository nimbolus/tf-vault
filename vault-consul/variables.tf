variable "namespace" {
  default = "vault"
}

variable "release_name" {
  default = "vault"
}

variable "chart_version" {
  default = "0.12.0"
}

variable "vault_domain" {
  default = "vault.cluster.local"
}

variable "tls_secret_name" {
  default = "vault-tls"
}

variable "consul_address" {
  default = "HOST_IP:8501"
}

variable "consul_namespace" {
  default = "consul"
}

variable "consul_ca_secret_name" {
  default = "consul-consul-ca-cert"
}

variable "auto_unseal_enable" {
  default = false
}

variable "auto_unseal_vault_service_address" {
  default = "vault.example.com"
}

variable "auto_unseal_vault_mount_path" {
  default = "transit"
}

variable "auto_unseal_auth_path" {
  default = "auth/kubernetes"
}

variable "auto_unseal_vault_role" {
  default = "vault-unseal"
}

variable "ingress_ssl_passthrough_enable" {
  default = false
}
