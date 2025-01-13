path "kv/data/elasticsearch/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/elasticsearch/*" {
  capabilities = ["list"]
} 