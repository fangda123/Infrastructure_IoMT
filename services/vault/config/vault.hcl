storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:${VAULT_PORT}"
  tls_disable = 1
}

api_addr = "${VAULT_API_ADDR}"
cluster_addr = "${VAULT_CLUSTER_ADDR}"

disable_mlock = true
ui = true