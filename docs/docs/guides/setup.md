---
sidebar_position: 1
---

# Setup do Ambiente

Guia completo para configurar o ambiente de desenvolvimento do Imperium Backend.

## Pre-requisitos

| Ferramenta | Versao | Descricao |
|------------|--------|-----------|
| **Go** | 1.24+ | Linguagem principal |
| **Docker** | 20.10+ | Containerizacao |
| **Docker Compose** | 2.0+ | Orquestracao |
| **Git** | 2.0+ | Controle de versao |

## Instalacao Rapida (Docker)

A forma mais rapida de rodar o projeto:

```bash
# Clone o repositorio
git clone <repo-url>
cd Imperium-App/backend

# Copie o arquivo de ambiente
cp .env.example .env

# Inicie todos os servicos
docker-compose up -d
```

Pronto! Acesse:
- **API:** http://localhost:8080
- **Swagger:** http://localhost:8080/swagger/
- **MongoDB Express:** http://localhost:8081
- **Grafana:** http://localhost:3001 (admin/imperium123)
- **Prometheus:** http://localhost:9091

## Instalacao Manual (Desenvolvimento)

### 1. Instalar Go

```bash
# macOS
brew install go

# Linux
wget https://go.dev/dl/go1.24.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/bin
```

### 2. Instalar MongoDB

```bash
# Via Docker (recomendado)
docker run -d --name mongo -p 27017:27017 mongo:7

# macOS
brew tap mongodb/brew
brew install mongodb-community

# Linux
# Siga: https://docs.mongodb.com/manual/installation/
```

### 3. Configurar Variaveis de Ambiente

Crie o arquivo `.env`:

```bash
# .env
MONGO_URI=mongodb://localhost:27017/imperium
PORT=8080
JWT_SECRET=sua-chave-secreta-aqui-mude-em-producao
JWT_EXPIRY=168h
DB_NAME=imperium
```

### 4. Instalar Dependencias

```bash
cd backend
go mod download
```

### 5. Gerar Documentacao Swagger

```bash
# Instalar swag CLI
go install github.com/swaggo/swag/cmd/swag@latest

# Gerar docs
swag init -g cmd/api/main.go -o docs
```

### 6. Executar

```bash
go run cmd/api/main.go
```

## Estrutura do Projeto

```
backend/
├── cmd/
│   └── api/
│       └── main.go          # Ponto de entrada
├── internal/
│   ├── config/              # Configuracoes
│   ├── database/            # Conexao MongoDB
│   ├── handlers/            # Controllers HTTP
│   ├── middleware/          # Middlewares
│   ├── models/              # Estruturas de dados
│   └── router/              # Rotas
├── docs/                    # Swagger gerado
├── monitoring/              # Configs Prometheus/Grafana
├── docker-compose.yml
├── Dockerfile
├── go.mod
└── go.sum
```

## Comandos Uteis

```bash
# Executar em desenvolvimento
go run cmd/api/main.go

# Build
go build -o main cmd/api/main.go

# Testes
go test ./...

# Lint
golangci-lint run

# Atualizar Swagger
swag init -g cmd/api/main.go -o docs
```

## Docker Compose

### Servicos Disponiveis

| Servico | Porta | Descricao |
|---------|-------|-----------|
| `api` | 8080 | Backend Go |
| `mongo` | 27017 | MongoDB |
| `mongo-express` | 8081 | UI do MongoDB |
| `prometheus` | 9091 | Metricas |
| `grafana` | 3001 | Dashboards |
| `loki` | 3100 | Logs |
| `promtail` | - | Coletor de logs |

### Comandos Docker

```bash
# Iniciar todos
docker-compose up -d

# Iniciar apenas API e MongoDB
docker-compose up -d api mongo

# Ver logs
docker-compose logs -f api

# Rebuild apos mudancas
docker-compose up -d --build api

# Parar tudo
docker-compose down

# Parar e limpar volumes
docker-compose down -v
```

## Verificacao

Teste se tudo esta funcionando:

```bash
# Health check
curl http://localhost:8080/api/v1/health
# {"status":"ok"}

# Registrar usuario
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456","name":"Test"}'
```

## Problemas Comuns

### Porta ja em uso

```bash
# Encontrar processo
lsof -i :8080

# Matar processo
kill -9 <PID>
```

### MongoDB nao conecta

```bash
# Verificar se esta rodando
docker ps | grep mongo

# Verificar logs
docker logs mongo
```

### Erro de permissao no Docker

```bash
# Adicionar usuario ao grupo docker
sudo usermod -aG docker $USER
# Fazer logout e login novamente
```
