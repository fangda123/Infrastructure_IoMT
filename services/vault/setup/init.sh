#!/bin/sh

# รอให้ Vault Server พร้อม
sleep 5

export VAULT_ADDR='http://0.0.0.0:8200'

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
    api_addr="http://0.0.0.0:8200" \
    cluster_addr="https://0.0.0.0:8201" \
    port="8200" \
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
    username="root" \
    password="example" \
    database="iomt_db" \
    express_user="admin" \
    express_pass="admin123" \
    cache_size="2"

# Redis
vault kv put kv/redis/config \
    port="6379" \
    password="redis123" \
    max_memory="2gb" \
    max_clients="10000"

# EMQX
vault kv put kv/emqx/config \
    dashboard_user="admin" \
    dashboard_pass="public" \
    allow_anonymous="false" \
    acl_nomatch="deny" \
    mqtt_port="1883" \
    ws_port="8083" \
    wss_port="8084" \
    ssl_port="8883" \
    dashboard_port="18083"

# Elasticsearch
vault kv put kv/elasticsearch/config \
    username="elastic" \
    password="elastic123" \
    heap_size="512m" \
    node_name="es01" \
    cluster_name="iomt-cluster" \
    http_port="9200" \
    tcp_port="9300"

# Kong
vault kv put kv/kong/config \
    pg_user="kong" \
    pg_password="kongpass" \
    pg_database="kong" \
    pg_host="kong-database" \
    proxy_port="8000" \
    proxy_ssl_port="8443" \
    admin_port="8001" \
    admin_ssl_port="8444" \
    manager_port="8002" \
    proxy_access_log="/dev/stdout" \
    admin_access_log="/dev/stdout" \
    proxy_error_log="/dev/stderr" \
    admin_error_log="/dev/stderr" \
    admin_listen="0.0.0.0:8001" \
    admin_ssl_listen="0.0.0.0:8444" \
    admin_gui_url="http://localhost:8002" \
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