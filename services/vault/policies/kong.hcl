path "kv/data/kong/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/kong/*" {
  capabilities = ["list"]
} 