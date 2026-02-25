# Imperium

Sistema completo de controle financeiro pessoal com app mobile, API backend, e **TRON** - um sistema autonomo de desenvolvimento com agentes de IA.

## Estrutura do Projeto

```
imperium/
├── app/           # App Flutter (iOS, Android, Web)
├── backend/       # API Go + MongoDB + TRON
├── docs/          # Documentacao Docusaurus
└── landing/       # Landing page Next.js
```

## Stack

| Componente | Tecnologia | Porta |
|------------|------------|-------|
| App | Flutter/Dart | - |
| Backend | Go 1.24 + MongoDB | 8080 |
| Docs | Docusaurus | 3000 |
| Landing | Next.js | 3002 |
| Swagger | Swagger UI | 8080/swagger |
| Grafana | Grafana | 3001 |
| Prometheus | Prometheus | 9091 |

---

## Quick Start (Tudo)

```bash
# 1. Backend (Docker)
cd backend
docker-compose up -d

# 2. Docs
cd docs
npm install && npm start

# 3. Landing
cd landing
npm install && npm run dev

# 4. App Flutter
cd app
flutter pub get && flutter run
```

---

## Backend (API)

API REST em Go com MongoDB, autenticacao JWT, e sistema TRON.

### Rodar

```bash
cd backend

# Com Docker (recomendado)
docker-compose up -d

# Ou localmente
go run cmd/api/main.go
```

### URLs

| Servico | URL |
|---------|-----|
| API | http://localhost:8080 |
| Swagger | http://localhost:8080/swagger/ |
| Health | http://localhost:8080/api/v1/health |
| Metrics | http://localhost:8080/metrics |
| Mongo Express | http://localhost:8081 |
| Grafana | http://localhost:3001 |
| Prometheus | http://localhost:9091 |

### Variaveis de Ambiente

```bash
MONGO_URI=mongodb://localhost:27017/imperium
JWT_SECRET=your-secret-key
CLAUDE_API_KEY=sk-ant-...    # Para TRON
GITHUB_TOKEN=ghp_...         # Para TRON
```

### Endpoints Principais

```bash
# Auth
POST /api/v1/auth/register
POST /api/v1/auth/login

# Profile
GET  /api/v1/profile
PUT  /api/v1/profile

# Transactions
GET  /api/v1/transactions
POST /api/v1/transactions

# Accounts
GET  /api/v1/accounts
POST /api/v1/accounts

# TRON
GET  /api/v1/tron/projects
POST /api/v1/tron/projects
POST /api/v1/tron/projects/{id}/cycle
```

---

## Docs (Documentacao)

Documentacao completa usando Docusaurus.

### Rodar

```bash
cd docs
npm install
npm start
```

### URL

http://localhost:3000

### Build para Producao

```bash
npm run build
npm run serve
```

---

## Landing (Site)

Landing page em Next.js com Tailwind CSS.

### Rodar

```bash
cd landing
npm install
npm run dev
```

### URL

http://localhost:3002

### Build para Producao

```bash
npm run build
npm start
```

---

## App (Flutter)

App mobile/web em Flutter.

### Rodar

```bash
cd app
flutter pub get

# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome

# Todos devices
flutter run
```

### Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

---

## TRON - Autonomous Software House

Sistema de agentes de IA que evoluem repositorios automaticamente.

### Agentes

| Agente | Funcao |
|--------|--------|
| Board (CTO) | Decide qual repo e tipo de trabalho |
| PM | Gera tasks detalhadas |
| Dev | Implementa usando Claude Code |
| QA | Revisa codigo e testes |
| Integration | Propaga mudancas cross-repo |

### Usar TRON

```bash
# 1. Criar projeto
curl -X POST http://localhost:8080/api/v1/tron/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Meu Projeto", "frequency": "normal"}'

# 2. Adicionar repo
curl -X POST http://localhost:8080/api/v1/tron/projects/{id}/repos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"github_url": "https://github.com/user/repo"}'

# 3. Disparar ciclo
curl -X POST http://localhost:8080/api/v1/tron/projects/{id}/cycle \
  -H "Authorization: Bearer $TOKEN"
```

### Dashboard Grafana

Acesse http://localhost:3001 (admin/imperium123) e veja o dashboard "TRON - Autonomous Software House".

---

## Desenvolvimento

### Regenerar Swagger

```bash
cd backend
go install github.com/swaggo/swag/cmd/swag@latest
swag init -g cmd/api/main.go -o docs
docker-compose up -d --build api
```

### Rodar Testes

```bash
# Backend
cd backend && go test ./...

# App
cd app && flutter test
```

### Logs

```bash
# Backend
docker-compose logs -f api

# Todos
docker-compose logs -f
```

---

## Credenciais Default (Dev)

| Servico | Usuario | Senha |
|---------|---------|-------|
| Grafana | admin | imperium123 |
| Mongo Express | - | (sem auth) |

---

## Links Uteis

- [Swagger UI](http://localhost:8080/swagger/)
- [Documentacao](http://localhost:3000)
- [Grafana](http://localhost:3001)
- [Mongo Express](http://localhost:8081)
