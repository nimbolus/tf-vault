resource "kubernetes_secret" "vault_consul_token" {
  metadata {
    name      = "vault-consul-token"
    namespace = var.namespace
  }

  data = {
    token = data.consul_acl_token_secret_id.vault.secret_id
  }
}

resource "helm_release" "vault" {
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  name       = var.release_name
  namespace  = var.namespace
  version    = var.chart_version
  values = [<<-EOT
    global:
      tlsDisable: false
    server:
      ha:
        enabled: true
        replicas: ${var.server_replicas}
        config: |
          ui = true
          listener "tcp" {
            address = "[::]:8200"
            cluster_address = "[::]:8201"
            tls_cert_file = "/var/run/secrets/vault-tls/tls.crt"
            tls_key_file = "/var/run/secrets/vault-tls/tls.key"
            tls_min_version = "tls12"
          }
          storage "consul" {
            path = "${var.release_name}-vault"
            address = "${var.consul_address}"
            scheme = "https"
          }
          service_registration "kubernetes" {}
    %{if var.auto_unseal_enable}
      extraArgs: -config=/vault/unseal/token.hcl
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/service: ${var.auto_unseal_vault_service_address}
        vault.hashicorp.com/auth-path: ${var.auto_unseal_auth_path}
        vault.hashicorp.com/agent-inject-secret-token.hcl: 'true'
        vault.hashicorp.com/agent-inject-template-token.hcl: |
          {{- with secret "auth/token/lookup-self" -}}
          seal "transit" {
            address = "${var.auto_unseal_vault_service_address}"
            mount_path = "${var.auto_unseal_vault_mount_path}"
            key_name = "auto-unseal"
            # disable_renewal = "true"
            token = "{{.Data.id}}"
          }
          {{- end }}
        vault.hashicorp.com/role: '${var.auto_unseal_vault_role}'
        vault.hashicorp.com/secret-volume-path: '/vault/unseal'
    %{endif}
      extraSecretEnvironmentVars:
        - envName: CONSUL_HTTP_TOKEN
          secretName: vault-consul-token
          secretKey: token
      volumes:
        - name: consul-ca
          secret:
            secretName: consul-ca-cert
        - name: vault-tls
          secret:
            secretName: ${var.tls_secret_name}
      volumeMounts:
        - name: consul-ca
          mountPath: /var/run/secrets/consul-ca
        - name: vault-tls
          mountPath: /var/run/secrets/vault-tls
      ingress:
        enabled: true
    %{if var.ingress_ssl_passthrough_enable}
        annotations: |
          'nginx.ingress.kubernetes.io/ssl-passthrough': 'true'
    %{endif}
        hosts:
          - host: ${var.vault_domain}
            paths:
              - /
        tls:
          - hosts:
              - ${var.vault_domain}
            secretName: ${var.tls_secret_name}
    EOT
  ]
}

data "kubernetes_secret" "consul_ca" {
  metadata {
    name      = var.consul_ca_secret_name
    namespace = var.consul_namespace
  }
}

resource "kubernetes_secret" "vault_consul_ca" {
  metadata {
    name      = "consul-ca-cert"
    namespace = var.namespace
  }

  data = {
    "ca.crt" = data.kubernetes_secret.consul_ca.data["tls.crt"]
  }
}
