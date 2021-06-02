variable "namespace" {
  default = "vault"
}

variable "name" {
  default = "vault"
}

variable "kubernetes_auth_path" {
  default = "kubernetes"
}

variable "transit_secret_name" {
  default = "auto-unseal"
}

variable "transit_secret_type" {
  default = "aes256-gcm96"
}
