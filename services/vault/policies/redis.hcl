path "kv/data/redis/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/redis/*" {
  capabilities = ["list"]
} 