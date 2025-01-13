path "kv/data/mongodb/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/mongodb/*" {
  capabilities = ["list"]
} 