# terraform modules for HashiCorp Vault

## vault-consul
Deploys Vault server on Kubernetes and connects with existing HashiCorp Consul cluster.

## vault-transit
Addition to vault-consul module which can be deployed on a second Vault cluster to auto-unseal the main cluster with Vault's transit engine.

### Usage
1. Deploy Vault 1 (e.g. with vault-consul) - do NOT enable auto-unseal yet.
2. Repeat for Vault 2.
3. Deploy vault-transit for Vault 1 and Vault 2.
4. Enable auto-unseal for Vault 1 and init seal migration. You need to restart the Vault server pods.
5. Repeat for Vault 2.

### Import
If a vault-consul module instance is removed entirely the data is still available in Consul. So after redeploying these lines help to import the existing data paths.

```sh
NAME=vault
KUBERNETES_AUTH_NAME=kubernetes

terraform import module.vault_transit.vault_mount.transit $NAME-transit
terraform import module.vault_transit.vault_transit_secret_backend_key.auto_unseal $NAME-transit/keys/auto-unseal
terraform import module.vault_transit.vault_policy.vault_server $NAME-unseal
terraform import module.vault_transit.vault_auth_backend.kubernetes $KUBERNETES_AUTH_NAME
terraform import module.vault_transit.vault_kubernetes_auth_backend_config.kubernetes auth/$KUBERNETES_AUTH_NAME/config
terraform import module.vault_transit.vault_kubernetes_auth_backend_role.vault_server auth/$KUBERNETES_AUTH_NAME/role/$NAME-unseal
```
