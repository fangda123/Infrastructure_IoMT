#!/bin/sh

# รอให้ Vault Server พร้อม
sleep 5

export VAULT_ADDR="${VAULT_API_ADDR}"

# ตรวจสอบสถานะ initialization
INIT_STATUS=$(vault status 2>&1)
INITIALIZED=$(echo "$INIT_STATUS" | grep "Initialized" | awk '{print $2}')

if [ "$INITIALIZED" = "false" ]; then
    echo "Initializing Vault..."
    # Initialize Vault with key sharing
    vault operator init \
        -key-shares=5 \
        -key-threshold=3 \
        -format=json > /vault/keys/init.json

    # แยกเก็บ keys
    cat /vault/keys/init.json | jq -r '.unseal_keys_b64[0]' > /vault/keys/unseal_key_1
    cat /vault/keys/init.json | jq -r '.unseal_keys_b64[1]' > /vault/keys/unseal_key_2
    cat /vault/keys/init.json | jq -r '.unseal_keys_b64[2]' > /vault/keys/unseal_key_3
    cat /vault/keys/init.json | jq -r '.unseal_keys_b64[3]' > /vault/keys/unseal_key_4
    cat /vault/keys/init.json | jq -r '.unseal_keys_b64[4]' > /vault/keys/unseal_key_5
    cat /vault/keys/init.json | jq -r '.root_token' > /vault/keys/root_token

    # Unseal Vault
    echo "Unsealing Vault..."
    for i in $(seq 1 3); do
        KEY=$(cat /vault/keys/unseal_key_$i)
        vault operator unseal "$KEY"
    done

    # เก็บ Root Token
    export VAULT_TOKEN=$(cat /vault/keys/root_token)

    echo "Vault initialized and unsealed successfully"
    echo "Keys are stored in /vault/keys/"
    echo "Please save these keys in a secure location"
else
    echo "Vault is already initialized"
    # ตรวจสอบว่า Vault ถูก seal หรือไม่
    SEALED=$(echo "$INIT_STATUS" | grep "Sealed" | awk '{print $2}')
    if [ "$SEALED" = "true" ] && [ -f "/vault/keys/unseal_key_1" ]; then
        echo "Unsealing Vault..."
        for i in $(seq 1 3); do
            KEY=$(cat /vault/keys/unseal_key_$i)
            vault operator unseal "$KEY"
        done
    fi
    # ใช้ root token ที่มีอยู่
    export VAULT_TOKEN=$(cat /vault/keys/root_token)
fi

# รอให้ Vault พร้อมใช้งาน
echo "Waiting for Vault to be ready..."
COUNTER=0
MAX_TRIES=30
until vault status > /dev/null 2>&1 || [ $COUNTER -eq $MAX_TRIES ]; do
    sleep 1
    COUNTER=$((COUNTER+1))
    if [ $((COUNTER%5)) -eq 0 ]; then
        echo "Still waiting... ($COUNTER seconds)"
    fi
done

if [ $COUNTER -eq $MAX_TRIES ]; then
    echo "Error: Vault failed to start after $MAX_TRIES seconds"
    exit 1
fi

echo "Vault is ready!"

# เปิดใช้งาน KV Secrets Engine
vault secrets enable -version=2 kv 2>/dev/null || true

# ตั้งค่า Vault เอง
vault kv put kv/vault/config \
    api_addr="${VAULT_API_ADDR}" \
    cluster_addr="${VAULT_CLUSTER_ADDR}" \
    port="${VAULT_PORT}" \
    tls_disable="1" \
    storage_path="/vault/file" \
    ui="true" \
    disable_mlock="true" \
    key_shares="5" \
    key_threshold="3" \
    log_level="info" \
    log_format="standard"

# สร้าง policy สำหรับแต่ละบริการ
for policy in redis emqx mongodb elasticsearch kong; do
    vault policy write $policy /vault/policies/$policy.hcl
done

# สร้าง token สำหรับแต่ละบริการ
for service in redis emqx mongodb elasticsearch kong; do
    vault token create -policy=$service -format=json | jq -r '.auth.client_token' > /vault/keys/${service}_token
done

# เพิ่มข้อมูล secret และการตั้งค่า Docker สำหรับแต่ละบริการ

# MongoDB
vault kv put kv/mongodb/config \
    username="${MONGO_ROOT_USERNAME}" \
    password="${MONGO_ROOT_PASSWORD}" \
    database="${MONGO_DATABASE}" \
    express_user="${MONGO_EXPRESS_USERNAME}" \
    express_pass="${MONGO_EXPRESS_PASSWORD}" \
    cache_size="${MONGO_CACHE_SIZE}"

# Redis
vault kv put kv/redis/config \
    port="${REDIS_PORT}" \
    password="${REDIS_PASSWORD}" \
    max_memory="${REDIS_MAX_MEMORY}" \
    max_clients="${REDIS_MAX_CLIENTS}"

# EMQX
vault kv put kv/emqx/config \
    dashboard_user="${EMQX_DASHBOARD_USER}" \
    dashboard_pass="${EMQX_DASHBOARD_PASSWORD}" \
    allow_anonymous="${EMQX_ALLOW_ANONYMOUS}" \
    acl_nomatch="${EMQX_ACL_NOMATCH}" \
    mqtt_port="${EMQX_MQTT_PORT}" \
    ws_port="${EMQX_WS_PORT}" \
    wss_port="${EMQX_WSS_PORT}" \
    ssl_port="${EMQX_SSL_PORT}" \
    dashboard_port="${EMQX_DASHBOARD_PORT}"

# Elasticsearch
vault kv put kv/elasticsearch/config \
    username="${ES_USERNAME}" \
    password="${ES_PASSWORD}" \
    heap_size="${ES_HEAP_SIZE}" \
    node_name="${ES_NODE_NAME}" \
    cluster_name="${ES_CLUSTER_NAME}" \
    http_port="${ES_HTTP_PORT}" \
    tcp_port="${ES_TCP_PORT}"

# Kong
vault kv put kv/kong/config \
    pg_user="${POSTGRES_USER}" \
    pg_password="${POSTGRES_PASSWORD}" \
    pg_database="${KONG_PG_DATABASE}" \
    pg_host="${KONG_DATABASE_HOSTNAME}" \
    proxy_port="${KONG_PROXY_PORT}" \
    proxy_ssl_port="${KONG_PROXY_SSL_PORT}" \
    admin_port="${KONG_ADMIN_PORT}" \
    admin_ssl_port="${KONG_ADMIN_SSL_PORT}" \
    manager_port="${KONG_MANAGER_PORT}" \
    proxy_access_log="/dev/stdout" \
    admin_access_log="/dev/stdout" \
    proxy_error_log="/dev/stderr" \
    admin_error_log="/dev/stderr" \
    admin_listen="0.0.0.0:${KONG_ADMIN_PORT}" \
    admin_ssl_listen="0.0.0.0:${KONG_ADMIN_SSL_PORT}" \
    admin_gui_url="http://${KONG_HOSTNAME}:${KONG_MANAGER_PORT}" \
    admin_gui_path="/manager" \
    plugins="bundled,jwt,rate-limiting,cors" \
    migration_image="kong:3.3" \
    kong_image="kong:3.3"

# แสดงตำแหน่งที่เก็บ keys
echo "================ Vault Keys Location ================"
echo "Unseal Keys: /vault/keys/unseal_key_[1-5]"
echo "Root Token: /vault/keys/root_token"
echo "Service Tokens: /vault/keys/[service]_token"
echo "=================================================="