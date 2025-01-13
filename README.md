# Infrastructure IoMT Platform

[![gRPC](https://img.shields.io/badge/gRPC-v1.9.13-blue.svg)](https://grpc.io/)
[![MongoDB](https://img.shields.io/badge/MongoDB-v6.0-green.svg)](https://www.mongodb.com/)
[![Redis](https://img.shields.io/badge/Redis-v7.2-red.svg)](https://redis.io/)
[![ElasticSearch](https://img.shields.io/badge/Elasticsearch-v8.11.1-yellow.svg)](https://www.elastic.co/)
[![EMQX](https://img.shields.io/badge/EMQX-v5.4.1-purple.svg)](https://www.emqx.io/)
[![Kong](https://img.shields.io/badge/Kong-v3.5-blue.svg)](https://konghq.com/)
[![Vault](https://img.shields.io/badge/Vault-v1.15-black.svg)](https://www.vaultproject.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-v2.45-orange.svg)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-v10.2-orange.svg)](https://grafana.com/)

## Service Endpoints & Port Mapping

### Development Environment (localhost)

| Service | Local URL | Production URL | Port | Protocol | Description |
|---------|-----------|----------------|------|----------|-------------|
| **EMQX** |
| MQTT Broker | mqtt://localhost:1883 | mqtt://mqtt.iomt.dev | 1883 | MQTT | MQTT Broker Port |
| MQTT/SSL | mqtts://localhost:8883 | mqtts://mqtt.iomt.dev | 8883 | MQTT/SSL | Secure MQTT Port |
| WebSocket | ws://localhost:8083 | ws://mqtt.iomt.dev/mqtt | 8083 | WS | WebSocket Port |
| WebSocket/SSL | wss://localhost:8084 | wss://mqtt.iomt.dev/mqtt | 8084 | WSS | Secure WebSocket Port |
| Dashboard | http://localhost:18083 | https://mqtt-dashboard.iomt.dev | 18083 | HTTP | EMQX Dashboard |
| **MongoDB** |
| Database | mongodb://localhost:27018 | mongodb://db.iomt.dev | 27018 | MongoDB | Primary Database |
| Express UI | http://localhost:8081 | https://db-admin.iomt.dev | 8081 | HTTP | MongoDB Express UI |
| **Redis** |
| Database | redis://localhost:6379 | redis://cache.iomt.dev | 6379 | Redis | Cache Database |
| RedisInsight | http://localhost:8001 | https://cache-admin.iomt.dev | 8001 | HTTP | Redis Management UI |
| **Elasticsearch** |
| HTTP API | http://localhost:9200 | https://es.iomt.dev | 9200 | HTTP | Elasticsearch API |
| Transport | localhost:9300 | es-transport.iomt.dev | 9300 | TCP | ES Transport |
| Kibana | http://localhost:5601 | https://kibana.iomt.dev | 5601 | HTTP | Kibana Dashboard |
| **Kong Gateway** |
| Proxy | http://localhost:8000 | https://api.iomt.dev | 8000 | HTTP | API Gateway |
| Proxy SSL | https://localhost:8443 | https://api.iomt.dev | 8443 | HTTPS | Secure API Gateway |
| Admin API | http://localhost:8001 | https://api-admin.iomt.dev | 8001 | HTTP | Kong Admin API |
| Manager | http://localhost:8002 | https://api-manager.iomt.dev | 8002 | HTTP | Kong Manager UI |
| **Vault** |
| UI/API | http://localhost:8200 | https://vault.iomt.dev | 8200 | HTTP | Vault UI & API |
| Cluster | https://localhost:8201 | https://vault-cluster.iomt.dev | 8201 | HTTPS | Vault Cluster |
| **Monitoring** |
| Prometheus | http://localhost:9090 | https://metrics.iomt.dev | 9090 | HTTP | Metrics Collection |
| Grafana | http://localhost:3000 | https://monitor.iomt.dev | 3000 | HTTP | Monitoring Dashboard |
| **Development** |
| Mailpit SMTP | localhost:1025 | mail.iomt.dev | 1025 | SMTP | Mail Testing (SMTP) |
| Mailpit UI | http://localhost:8025 | https://mail-ui.iomt.dev | 8025 | HTTP | Mail Testing UI |

### Default Credentials

| Service | Username | Password | Note |
|---------|----------|----------|------|
| EMQX Dashboard | admin | public | Dashboard & MQTT Superuser |
| MongoDB | root | example | Root User |
| MongoDB Express | admin | admin123 | Web UI Access |
| Elasticsearch | elastic | elastic123 | Superuser |
| Kong Admin | admin | adminpass | Admin API Access |
| Grafana | admin | admin | Dashboard Access |
| Vault | - | - | Token-based Auth |

## Overview
ระบบโครงสร้างพื้นฐานสำหรับ Internet of Medical Things (IoMT) Platform ที่รองรับการทำงานแบบ Microservices Architecture พร้อมระบบ Monitoring และ Security ที่ครบครัน

## Architecture Components
โครงสร้างระบบประกอบด้วยส่วนประกอบหลักดังนี้:

### Message Broker & IoT Protocol
- **EMQX**: MQTT Broker สำหรับรับส่งข้อมูลจากอุปกรณ์ IoMT
  - Dashboard Port: 18083
  - MQTT Port: 1883
  - MQTT/SSL Port: 8883
  - WebSocket Port: 8083
  - WebSocket/SSL Port: 8084

### Databases
- **MongoDB**: ฐานข้อมูลหลักสำหรับเก็บข้อมูล
  - Port: 27017
  - Express Port: 8081

- **Redis**: In-memory Database สำหรับ Caching
  - Port: 6379
  - RedisInsight Port: 8001

- **Elasticsearch**: Search Engine และ Analytics
  - HTTP Port: 9200
  - Transport Port: 9300
  - Kibana Port: 5601

### API Gateway & Security
- **Kong**: API Gateway
  - Admin Port: 8001
  - Proxy Port: 8000
  - HTTPS Port: 8443

- **Vault**: Secret Management
  - UI/API Port: 8200

### Monitoring & Logging
- **Prometheus**: Metrics Collection
  - Port: 9090

- **Grafana**: Visualization & Monitoring
  - Port: 3000

- **Mailpit**: Mail Testing
  - SMTP Port: 1025
  - Web UI Port: 8025

## Quick Start
1. Clone repository
2. Copy `.env.example` to `.env` และกำหนดค่าตามต้องการ
3. รันระบบด้วยคำสั่ง:
```bash
docker-compose up -d
```

## Service URLs
| Service | URL | Description |
|---------|-----|-------------|
| EMQX Dashboard | http://localhost:18083 | MQTT Broker Management |
| MongoDB Express | http://localhost:8081 | MongoDB Management UI |
| RedisInsight | http://localhost:8001 | Redis Management UI |
| Kibana | http://localhost:5601 | Elasticsearch Management |
| Kong Admin | http://localhost:8001 | API Gateway Admin |
| Vault UI | http://localhost:8200 | Secret Management |
| Prometheus | http://localhost:9090 | Metrics & Monitoring |
| Grafana | http://localhost:3000 | Visualization Dashboard |
| Mailpit | http://localhost:8025 | Mail Testing Interface |

## Environment Variables
โปรเจคใช้ไฟล์ `.env` สำหรับกำหนดค่าต่างๆ สามารถดูตัวอย่างได้จาก `.env.example`

## Security Considerations
- ทุก Service มีการกำหนด Authentication
- Kong Gateway ทำหน้าที่ Rate Limiting และ Security Layer
- Vault จัดการ Secrets และ Credentials
- SSL/TLS สำหรับการสื่อสารที่สำคัญ

## Monitoring & Logging
- Prometheus เก็บ Metrics ของทุก Service
- Grafana แสดงผล Dashboard สำหรับ Monitoring
- ELK Stack สำหรับ Log Management

## Credits
พัฒนาโดย MasterJXMaN

## License
MIT License 
