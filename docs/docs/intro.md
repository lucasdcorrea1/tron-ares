---
slug: /
sidebar_position: 1
---

# Imperium Backend

API de controle financeiro pessoal construida em Go.

## Quick Start

```bash
cd backend
docker-compose up -d
```

**URLs:**
- API: http://localhost:8080
- Swagger: http://localhost:8080/swagger/
- Grafana: http://localhost:3001

## Stack

| Tech | Descricao |
|------|-----------|
| Go 1.24 | Backend |
| MongoDB | Database |
| JWT | Auth |
| Docker | Deploy |

## Endpoints

| Metodo | Rota | Descricao |
|--------|------|-----------|
| POST | `/auth/register` | Criar conta |
| POST | `/auth/login` | Login |
| GET | `/profile` | Perfil |
| GET | `/transactions` | Listar transacoes |
| POST | `/transactions` | Nova transacao |
| GET | `/accounts` | Contas bancarias |
| GET | `/profile/stats` | Estatisticas |
| GET | `/tron/projects` | Projetos TRON |
| POST | `/tron/projects` | Criar projeto TRON |
| GET | `/tron/tasks` | Tasks do TRON |

Base URL: `http://localhost:8080/api/v1`

## TRON - Autonomous Software House

O Imperium inclui o **TRON**, um sistema autonomo de desenvolvimento que usa agentes de IA para evoluir repositorios automaticamente.

```bash
# Criar projeto TRON
curl -X POST http://localhost:8080/api/v1/tron/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Meu Projeto", "frequency": "normal"}'
```

Veja a [documentacao completa do TRON](/tron/overview).

## Autenticacao

```bash
# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"123456"}'

# Usar token
curl http://localhost:8080/api/v1/profile \
  -H "Authorization: Bearer <token>"
```

## Arquitetura

```
backend/
├── cmd/api/main.go       # Entrada
├── internal/
│   ├── config/           # Env vars
│   ├── database/         # MongoDB
│   ├── handlers/         # Controllers
│   ├── middleware/       # Auth, CORS, Logger
│   ├── models/           # Structs
│   └── router/           # Rotas
└── docs/                 # Swagger
```

---

Veja a [API Reference](/api/endpoints) para documentacao completa.
