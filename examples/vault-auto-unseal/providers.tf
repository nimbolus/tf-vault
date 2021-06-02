provider "kubernetes" {
  config_path = "kubeconfig.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "kubeconfig.yaml"
}

data "kubernetes_secret" "consul_bootstrap_token" {
  metadata {
    namespace = "consul"
    name      = "consul-consul-bootstrap-acl-token"
  }
}

provider "consul" {
  address    = "consul.infra.nimbolus.de"
  scheme     = "https"
  datacenter = "fsn"
  token      = data.kubernetes_secret.consul_bootstrap_token.data["token"]
}
