---
sidebar_position: 1
---

# API Reference

Base URL: `http://localhost:8080/api/v1`

:::tip Swagger UI
Acesse a documentacao interativa em [http://localhost:8080/swagger/](http://localhost:8080/swagger/)
:::

---

## Autenticacao

### Registrar Usuario

<span className="api-method api-method--post">POST</span> `/auth/register`

Cria uma nova conta de usuario.

**Request Body:**

```json
{
  "email": "usuario@email.com",
  "password": "senha123",
  "name": "Nome do Usuario"
}
```

**Response:** `201 Created`

```json
{
  "user": {
    "id": "65abc123def456789",
    "email": "usuario@email.com",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "profile": {
    "id": "65abc123def456790",
    "user_id": "65abc123def456789",
    "name": "Nome do Usuario",
    "settings": {
      "currency": "BRL",
      "language": "pt-BR"
    }
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Erros:**

| Status | Descricao |
|--------|-----------|
| `400` | Campos obrigatorios faltando |
| `409` | Email ja cadastrado |

---

### Login

<span className="api-method api-method--post">POST</span> `/auth/login`

Autentica um usuario existente.

**Request Body:**

```json
{
  "email": "usuario@email.com",
  "password": "senha123"
}
```

**Response:** `200 OK`

```json
{
  "user": { ... },
  "profile": { ... },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

### Dados do Usuario Logado

<span className="api-method api-method--get">GET</span> `/auth/me`

:::caution Autenticacao Necessaria
Header: `Authorization: Bearer <token>`
:::

Retorna os dados do usuario autenticado.

**Response:** `200 OK`

```json
{
  "user": {
    "id": "65abc123def456789",
    "email": "usuario@email.com",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "profile": {
    "id": "65abc123def456790",
    "name": "Nome do Usuario",
    "avatar": "data:image/jpeg;base64,...",
    "settings": { ... }
  }
}
```

---

## Perfil

### Obter Perfil

<span className="api-method api-method--get">GET</span> `/profile`

**Response:** `200 OK`

```json
{
  "id": "65abc123def456790",
  "user_id": "65abc123def456789",
  "name": "Nome do Usuario",
  "avatar": "data:image/jpeg;base64,...",
  "bio": "Minha bio",
  "settings": {
    "currency": "BRL",
    "language": "pt-BR",
    "theme": {
      "mode": "dark",
      "primary_color": "#D4AF37",
      "accent_color": "#E0C563"
    },
    "first_day_of_week": 0,
    "date_format": "DD/MM/YYYY"
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-20T15:45:00Z"
}
```

---

### Atualizar Perfil

<span className="api-method api-method--put">PUT</span> `/profile`

**Request Body:**

```json
{
  "name": "Novo Nome",
  "bio": "Nova bio",
  "settings": {
    "currency": "USD",
    "theme": {
      "mode": "light",
      "primary_color": "#3498db"
    }
  }
}
```

---

### Upload de Avatar

<span className="api-method api-method--post">POST</span> `/profile/avatar`

**Content-Type:** `multipart/form-data`

| Campo | Tipo | Descricao |
|-------|------|-----------|
| `avatar` | File | Imagem PNG ou JPEG (max 5MB) |

A imagem e automaticamente redimensionada para 256x256 pixels.

---

## Transacoes

### Listar Transacoes

<span className="api-method api-method--get">GET</span> `/transactions`

Retorna todas as transacoes do usuario ordenadas por data (mais recente primeiro).

**Response:** `200 OK`

```json
[
  {
    "id": "65abc123def456791",
    "user_id": "65abc123def456789",
    "description": "Salario",
    "amount": 5000.00,
    "type": "income",
    "category": "salary",
    "date": "2024-01-15T00:00:00Z",
    "created_at": "2024-01-15T10:30:00Z"
  },
  {
    "id": "65abc123def456792",
    "description": "Supermercado",
    "amount": 350.50,
    "type": "expense",
    "category": "food",
    "date": "2024-01-16T00:00:00Z"
  }
]
```

---

### Criar Transacao

<span className="api-method api-method--post">POST</span> `/transactions`

**Request Body:**

```json
{
  "description": "Almoco",
  "amount": 45.90,
  "type": "expense",
  "category": "food",
  "date": "2024-01-20T12:00:00Z"
}
```

**Tipos disponiveis:** `income`, `expense`

**Categorias disponiveis:**

| Categoria | Descricao |
|-----------|-----------|
| `food` | Alimentacao |
| `transport` | Transporte |
| `housing` | Moradia |
| `leisure` | Lazer |
| `health` | Saude |
| `education` | Educacao |
| `salary` | Salario |
| `freelance` | Freelance |
| `other` | Outros |

---

### Obter Transacao

<span className="api-method api-method--get">GET</span> `/transactions/{id}`

---

### Atualizar Transacao

<span className="api-method api-method--put">PUT</span> `/transactions/{id}`

**Request Body:**

```json
{
  "description": "Almoco atualizado",
  "amount": 50.00
}
```

---

### Deletar Transacao

<span className="api-method api-method--delete">DELETE</span> `/transactions/{id}`

**Response:** `204 No Content`

---

### Obter Saldo

<span className="api-method api-method--get">GET</span> `/transactions/balance`

**Response:** `200 OK`

```json
{
  "balance": 4649.50,
  "total_income": 5000.00,
  "total_expenses": 350.50
}
```

---

## Contas Conectadas

### Listar Contas

<span className="api-method api-method--get">GET</span> `/accounts`

**Response:** `200 OK`

```json
[
  {
    "id": "65abc123def456793",
    "provider": "nubank",
    "account_type": "checking",
    "account_name": "Conta Principal",
    "last_four": "1234",
    "balance": 2500.00,
    "color": "#8A05BE",
    "icon": "nubank",
    "is_active": true,
    "last_sync": "2024-01-20T10:00:00Z"
  }
]
```

---

### Conectar Conta

<span className="api-method api-method--post">POST</span> `/accounts`

**Request Body:**

```json
{
  "provider": "nubank",
  "account_type": "checking",
  "account_name": "Minha Conta",
  "last_four": "1234",
  "balance": 1500.00
}
```

**Provedores disponiveis:**

| Provider | Nome |
|----------|------|
| `nubank` | Nubank |
| `itau` | Itau |
| `bradesco` | Bradesco |
| `santander` | Santander |
| `bb` | Banco do Brasil |
| `caixa` | Caixa |
| `inter` | Inter |
| `c6` | C6 Bank |
| `picpay` | PicPay |
| `mercadopago` | Mercado Pago |

**Tipos de conta:** `checking`, `savings`, `credit`

---

### Sincronizar Saldo

<span className="api-method api-method--post">POST</span> `/accounts/{id}/sync`

**Request Body:**

```json
{
  "balance": 2750.00
}
```

---

### Resumo das Contas

<span className="api-method api-method--get">GET</span> `/accounts/summary`

**Response:** `200 OK`

```json
{
  "total_balance": 5000.00,
  "total_accounts": 3,
  "checking_balance": 2500.00,
  "savings_balance": 2000.00,
  "credit_balance": 500.00,
  "by_provider": {
    "nubank": { "count": 1, "balance": 2500.00 },
    "itau": { "count": 2, "balance": 2500.00 }
  }
}
```

---

## Estatisticas

### Estatisticas do Perfil

<span className="api-method api-method--get">GET</span> `/profile/stats`

Retorna estatisticas completas para dashboards e graficos.

**Response:** `200 OK`

```json
{
  "total_balance": 15000.00,
  "monthly_income": 8000.00,
  "monthly_expenses": 3500.00,
  "monthly_savings": 4500.00,
  "transaction_count": 150,
  "top_categories": [
    { "category": "food", "amount": 1200.00, "percentage": 34.3, "color": "#FF6B6B" },
    { "category": "transport", "amount": 800.00, "percentage": 22.9, "color": "#4ECDC4" }
  ],
  "monthly_trend": [
    { "month": "2024-01", "income": 8000, "expenses": 3500, "balance": 4500 },
    { "month": "2023-12", "income": 7500, "expenses": 4000, "balance": 3500 }
  ],
  "comparison_last_month": {
    "income_change": 6.67,
    "expense_change": -12.5,
    "savings_change": 28.57
  },
  "connected_accounts": 3
}
```

---

### Breakdown de Despesas

<span className="api-method api-method--get">GET</span> `/profile/stats/breakdown`

**Query Parameters:**

| Param | Tipo | Default | Valores |
|-------|------|---------|---------|
| `period` | string | `month` | `week`, `month`, `year`, `all` |

---

### Breakdown de Receitas

<span className="api-method api-method--get">GET</span> `/profile/stats/income`

**Query Parameters:**

| Param | Tipo | Default | Valores |
|-------|------|---------|---------|
| `period` | string | `month` | `week`, `month`, `year`, `all` |

---

### Estatisticas Diarias

<span className="api-method api-method--get">GET</span> `/profile/stats/daily`

**Query Parameters:**

| Param | Tipo | Default | Max |
|-------|------|---------|-----|
| `days` | int | `30` | `90` |

**Response:** `200 OK`

```json
[
  { "date": "2024-01-20", "income": 0, "expenses": 150.00, "balance": -150.00 },
  { "date": "2024-01-19", "income": 500, "expenses": 80.00, "balance": 420.00 }
]
```

---

## Health & Metrics

### Health Check

<span className="api-method api-method--get">GET</span> `/health`

**Response:** `200 OK`

```json
{ "status": "ok" }
```

---

### Metricas Prometheus

<span className="api-method api-method--get">GET</span> `/metrics`

Retorna metricas no formato Prometheus para monitoramento.

---

## TRON - Autonomous Software House

:::info
Documentacao completa do TRON disponivel em [TRON API Reference](/tron/api)
:::

### Endpoints Principais

| Metodo | Rota | Descricao |
|--------|------|-----------|
| GET | `/tron/projects` | Listar projetos |
| POST | `/tron/projects` | Criar projeto |
| GET | `/tron/projects/{id}` | Obter projeto |
| POST | `/tron/projects/{id}/repos` | Adicionar repo |
| POST | `/tron/projects/{id}/cycle` | Disparar ciclo |
| GET | `/tron/tasks` | Listar tasks |
| GET | `/tron/decisions` | Listar decisoes |
| POST | `/tron/directives` | Criar diretiva |
| GET | `/tron/metrics` | Obter metricas |
| GET | `/tron/logs` | Listar logs |
| WS | `/tron/ws` | WebSocket stream |
