---
sidebar_position: 3
---

# Padrao de Documentacao

Guia para manter a documentacao consistente entre **Swagger** e **Docusaurus**.

## Regra de Ouro

> **Toda funcao publica deve ter documentacao Swagger E uma entrada no Docusaurus.**

---

## 1. Template Handler (Go + Swagger)

Ao criar um novo handler, use este template:

```go
// NomeDoHandler godoc
// @Summary Descricao curta (max 60 chars)
// @Description Descricao detalhada do que o endpoint faz
// @Tags nome-do-modulo
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "ID do recurso"
// @Param request body models.NomeRequest true "Dados da requisicao"
// @Success 200 {object} models.NomeResponse
// @Success 201 {object} models.NomeResponse "Criado com sucesso"
// @Failure 400 {string} string "Requisicao invalida"
// @Failure 401 {string} string "Nao autorizado"
// @Failure 404 {string} string "Nao encontrado"
// @Failure 500 {string} string "Erro interno"
// @Router /caminho/{id} [get]
func NomeDoHandler(w http.ResponseWriter, r *http.Request) {
    // implementacao
}
```

### Exemplo Real

```go
// CreateDebt godoc
// @Summary Criar nova divida
// @Description Registra uma nova divida com juros compostos
// @Tags debts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.CreateDebtRequest true "Dados da divida"
// @Success 201 {object} models.Debt
// @Failure 400 {string} string "Dados invalidos"
// @Failure 401 {string} string "Token invalido"
// @Router /debts [post]
func CreateDebt(w http.ResponseWriter, r *http.Request) {
    userID := middleware.GetUserID(r)
    // ...
}
```

---

## 2. Template Model (Go)

```go
// NomeModel representa [descricao]
// @Description Descricao do modelo para Swagger
type NomeModel struct {
    ID          primitive.ObjectID `json:"id" bson:"_id,omitempty" example:"65abc123def456789"`
    UserID      primitive.ObjectID `json:"user_id" bson:"user_id"`
    Name        string             `json:"name" bson:"name" example:"Exemplo"`
    Value       float64            `json:"value" bson:"value" example:"100.50"`
    IsActive    bool               `json:"is_active" bson:"is_active" example:"true"`
    CreatedAt   time.Time          `json:"created_at" bson:"created_at"`
}
```

---

## 3. Template Docusaurus (Markdown)

Para cada endpoint, adicione no arquivo `/docs/api/endpoints.md`:

```markdown
### Nome do Endpoint

<span className="api-method api-method--post">POST</span> `/caminho/do/endpoint`

Descricao do que o endpoint faz.

**Headers:**
- `Authorization: Bearer <token>` (obrigatorio)

**Request Body:**

| Campo | Tipo | Obrigatorio | Descricao |
|-------|------|-------------|-----------|
| `name` | string | Sim | Nome do recurso |
| `value` | number | Sim | Valor em reais |
| `is_active` | boolean | Nao | Default: true |

```json
{
  "name": "Exemplo",
  "value": 100.50,
  "is_active": true
}
```

**Response:** `201 Created`

```json
{
  "id": "65abc123def456789",
  "name": "Exemplo",
  "value": 100.50,
  "is_active": true,
  "created_at": "2024-01-20T10:30:00Z"
}
```

**Erros:**

| Status | Descricao |
|--------|-----------|
| `400` | Campos obrigatorios faltando |
| `401` | Token invalido ou expirado |
| `409` | Recurso ja existe |
```

---

## 4. Checklist Novo Endpoint

Ao criar um novo endpoint, verifique:

- [ ] Handler tem comentarios Swagger (`// @Summary`, `// @Router`, etc)
- [ ] Model tem tags `json`, `bson` e `example`
- [ ] Request/Response structs documentadas
- [ ] Endpoint adicionado em `/docs/api/endpoints.md`
- [ ] Swagger regenerado: `swag init -g cmd/api/main.go -o docs`
- [ ] Docusaurus buildando: `npm run build`

---

## 5. Comandos Uteis

```bash
# Regenerar Swagger apos mudancas
cd backend
swag init -g cmd/api/main.go -o docs

# Verificar se Docusaurus compila
cd docs
npm run build

# Rodar ambos localmente
# Terminal 1: Backend + Swagger
cd backend && go run cmd/api/main.go

# Terminal 2: Docusaurus
cd docs && npm start
```

---

## 6. Tags Swagger Padrao

| Tag | Uso |
|-----|-----|
| `auth` | Autenticacao (login, register, me) |
| `profile` | Perfil do usuario |
| `transactions` | Transacoes financeiras |
| `accounts` | Contas bancarias conectadas |
| `debts` | Dividas e emprestimos |
| `schedules` | Agendamentos |
| `stats` | Estatisticas e graficos |

---

## 7. Codigos de Status HTTP

Use consistentemente:

| Codigo | Quando Usar |
|--------|-------------|
| `200 OK` | GET, PUT, PATCH com sucesso |
| `201 Created` | POST criou recurso |
| `204 No Content` | DELETE com sucesso |
| `400 Bad Request` | Dados invalidos |
| `401 Unauthorized` | Token ausente/invalido |
| `403 Forbidden` | Sem permissao |
| `404 Not Found` | Recurso nao existe |
| `409 Conflict` | Duplicado (ex: email ja existe) |
| `500 Internal Server Error` | Erro no servidor |

---

## 8. Estrutura de Arquivos

```
backend/
├── internal/
│   ├── handlers/
│   │   └── novo_handler.go    # Com comentarios Swagger
│   └── models/
│       └── novo_model.go      # Com tags example
└── docs/
    ├── docs.go                # Gerado automaticamente
    ├── swagger.json           # Gerado automaticamente
    └── swagger.yaml           # Gerado automaticamente

docs/                          # Docusaurus
└── docs/
    └── api/
        └── endpoints.md       # Atualizar manualmente
```

---

## Exemplo Completo: Novo Modulo "Goals"

### 1. Model (`internal/models/goal.go`)

```go
package models

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

// Goal representa uma meta financeira
type Goal struct {
    ID           primitive.ObjectID `json:"id" bson:"_id,omitempty" example:"65abc123def456789"`
    UserID       primitive.ObjectID `json:"user_id" bson:"user_id"`
    Name         string             `json:"name" bson:"name" example:"Viagem para Europa"`
    TargetAmount float64            `json:"target_amount" bson:"target_amount" example:"15000"`
    CurrentAmount float64           `json:"current_amount" bson:"current_amount" example:"5000"`
    Deadline     time.Time          `json:"deadline" bson:"deadline"`
    CreatedAt    time.Time          `json:"created_at" bson:"created_at"`
}

// CreateGoalRequest para criar nova meta
type CreateGoalRequest struct {
    Name         string    `json:"name" example:"Viagem para Europa"`
    TargetAmount float64   `json:"target_amount" example:"15000"`
    Deadline     time.Time `json:"deadline"`
}
```

### 2. Handler (`internal/handlers/goals.go`)

```go
package handlers

// CreateGoal godoc
// @Summary Criar meta financeira
// @Description Cria uma nova meta de economia
// @Tags goals
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.CreateGoalRequest true "Dados da meta"
// @Success 201 {object} models.Goal
// @Failure 400 {string} string "Dados invalidos"
// @Failure 401 {string} string "Nao autorizado"
// @Router /goals [post]
func CreateGoal(w http.ResponseWriter, r *http.Request) {
    // implementacao
}

// GetGoals godoc
// @Summary Listar metas
// @Description Retorna todas as metas do usuario
// @Tags goals
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.Goal
// @Router /goals [get]
func GetGoals(w http.ResponseWriter, r *http.Request) {
    // implementacao
}
```

### 3. Docusaurus (`docs/api/endpoints.md`)

```markdown
## Metas Financeiras

### Criar Meta

<span className="api-method api-method--post">POST</span> `/goals`

Cria uma nova meta de economia.

**Request:**

```json
{
  "name": "Viagem para Europa",
  "target_amount": 15000,
  "deadline": "2024-12-31T00:00:00Z"
}
```

**Response:** `201 Created`

```json
{
  "id": "65abc123def456789",
  "name": "Viagem para Europa",
  "target_amount": 15000,
  "current_amount": 0,
  "deadline": "2024-12-31T00:00:00Z",
  "created_at": "2024-01-20T10:30:00Z"
}
```
```

### 4. Regenerar Docs

```bash
# Swagger
cd backend && swag init -g cmd/api/main.go -o docs

# Testar Docusaurus
cd ../docs && npm run build
```
