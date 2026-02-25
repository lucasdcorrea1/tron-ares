---
sidebar_position: 2
---

# TRON API Reference

Base URL: `http://localhost:8080/api/v1/tron`

:::tip Swagger UI
Documentacao interativa em [http://localhost:8080/swagger/](http://localhost:8080/swagger/)
:::

:::caution Autenticacao
Todos os endpoints requerem: `Authorization: Bearer <token>`
:::

---

## Projects

### Listar Projetos

<span className="api-method api-method--get">GET</span> `/tron/projects`

Retorna todos os projetos TRON do usuario.

**Response:** `200 OK`

```json
[
  {
    "id": "65abc123def456789",
    "name": "Meu Projeto",
    "description": "Descricao",
    "repos": ["65abc123def456790"],
    "frequency": "normal",
    "is_active": true,
    "daily_budget": 5.0,
    "created_at": "2024-01-15T10:30:00Z",
    "repos_count": 2,
    "tasks_in_backlog": 5,
    "tasks_completed": 42,
    "today_cost_usd": 0.35,
    "commits_today": 3
  }
]
```

---

### Criar Projeto

<span className="api-method api-method--post">POST</span> `/tron/projects`

**Request Body:**

```json
{
  "name": "Meu Projeto",
  "description": "Descricao do projeto",
  "references": ["https://docs.example.com"],
  "frequency": "normal",
  "daily_budget": 5.0
}
```

| Campo | Tipo | Obrigatorio | Default |
|-------|------|-------------|---------|
| `name` | string | Sim | - |
| `description` | string | Nao | "" |
| `references` | string[] | Nao | [] |
| `frequency` | string | Nao | "normal" |
| `daily_budget` | float | Nao | 5.0 |

**Frequencias:** `high`, `normal`, `low`

---

### Obter Projeto

<span className="api-method api-method--get">GET</span> `/tron/projects/{id}`

---

### Atualizar Projeto

<span className="api-method api-method--put">PUT</span> `/tron/projects/{id}`

**Request Body:**

```json
{
  "name": "Novo Nome",
  "is_active": false,
  "daily_budget": 10.0
}
```

---

### Deletar Projeto

<span className="api-method api-method--delete">DELETE</span> `/tron/projects/{id}`

**Response:** `204 No Content`

:::warning
Deleta o projeto e todos os dados associados (repos, tasks, logs, metrics).
:::

---

## Repositories

### Listar Repos do Projeto

<span className="api-method api-method--get">GET</span> `/tron/projects/{id}/repos`

**Response:** `200 OK`

```json
[
  {
    "id": "65abc123def456790",
    "project_id": "65abc123def456789",
    "github_url": "https://github.com/user/repo",
    "name": "repo",
    "is_main": true,
    "stack": {
      "language": "go",
      "framework": "net/http",
      "database": "mongodb",
      "tools": ["docker", "prometheus"]
    },
    "analysis": {
      "file_count": 45,
      "lines_of_code": 5000,
      "test_files": 12,
      "summary": "API backend em Go..."
    },
    "health": {
      "score": 85,
      "build_passing": true,
      "tests_passing": true,
      "last_check": "2024-01-20T10:00:00Z"
    }
  }
]
```

---

### Adicionar Repo Existente

<span className="api-method api-method--post">POST</span> `/tron/projects/{id}/repos`

**Request Body:**

```json
{
  "github_url": "https://github.com/user/repo",
  "is_main": true
}
```

---

### Criar Novo Repo

<span className="api-method api-method--post">POST</span> `/tron/projects/{id}/repos/create`

Cria um novo repositorio no GitHub a partir de template.

**Request Body:**

```json
{
  "name": "novo-repo",
  "description": "Descricao do novo repo",
  "template": "go-api",
  "is_private": false
}
```

**Templates disponiveis:** `go-api`, `ts-api`, `flutter-app`

---

### Analisar Repo

<span className="api-method api-method--post">POST</span> `/tron/repos/{id}/analyze`

Dispara uma analise completa do repositorio (stack detection, AI summary, etc).

---

## Tasks

### Listar Tasks

<span className="api-method api-method--get">GET</span> `/tron/tasks`

**Query Parameters:**

| Param | Tipo | Descricao |
|-------|------|-----------|
| `project_id` | string | Filtrar por projeto |
| `status` | string | Filtrar por status |
| `limit` | int | Max resultados (default: 50) |
| `offset` | int | Paginacao |

**Status disponiveis:** `backlog`, `ready`, `in_progress`, `in_review`, `done`, `rejected`

**Response:** `200 OK`

```json
{
  "tasks": [
    {
      "id": "65abc123def456791",
      "title": "Adicionar rate limiting",
      "description": "Implementar rate limiting na API",
      "status": "in_progress",
      "priority": "high",
      "size": "medium",
      "source_lens": "code",
      "spec": {
        "what": "Implementar rate limiting usando token bucket...",
        "files_to_create": ["internal/middleware/ratelimit.go"],
        "files_to_modify": ["internal/router/router.go"],
        "acceptance_criteria": ["Limite de 100 req/min por IP"],
        "edge_cases": ["IPs em whitelist"]
      },
      "branch_name": "feat/abc123-rate-limiting",
      "commits": [
        {"sha": "abc123", "message": "Add rate limiter middleware"}
      ],
      "qa_result": {
        "result": "APPROVED",
        "feedback": "Implementacao correta"
      }
    }
  ],
  "total": 15
}
```

---

### Obter Task

<span className="api-method api-method--get">GET</span> `/tron/tasks/{id}`

---

### Atualizar Task

<span className="api-method api-method--put">PUT</span> `/tron/tasks/{id}`

**Request Body:**

```json
{
  "status": "ready",
  "priority": "high"
}
```

---

## Agent Control

### Status dos Agents

<span className="api-method api-method--get">GET</span> `/tron/projects/{id}/agents/status`

**Response:** `200 OK`

```json
{
  "project_id": "65abc123def456789",
  "is_running": false,
  "last_cycle_at": "2024-01-20T18:00:00Z",
  "next_cycle_at": "2024-01-20T23:00:00Z",
  "agents": [
    {"type": "board", "status": "idle", "last_run": "..."},
    {"type": "pm", "status": "idle", "last_run": "..."},
    {"type": "dev", "status": "idle", "last_run": "..."},
    {"type": "qa", "status": "idle", "last_run": "..."},
    {"type": "integration", "status": "idle", "last_run": "..."}
  ]
}
```

---

### Disparar Ciclo Manual

<span className="api-method api-method--post">POST</span> `/tron/projects/{id}/cycle`

Inicia um ciclo completo dos agents imediatamente.

**Response:** `202 Accepted`

```json
{
  "message": "Cycle started",
  "cycle_id": "cycle_abc123"
}
```

---

## Decisions (CIO)

Decisoes que requerem aprovacao humana.

### Listar Decisoes Pendentes

<span className="api-method api-method--get">GET</span> `/tron/decisions`

**Query Parameters:**

| Param | Tipo | Descricao |
|-------|------|-----------|
| `project_id` | string | Filtrar por projeto |
| `status` | string | `pending`, `approved`, `rejected`, `timeout` |

**Response:** `200 OK`

```json
{
  "decisions": [
    {
      "id": "65abc123def456792",
      "level": "cio",
      "question": "Aprovar refatoracao da camada de banco de dados?",
      "context": "O Dev Agent propoe refatorar...",
      "options": [
        {"id": "opt1", "label": "Aprovar", "description": "..."},
        {"id": "opt2", "label": "Rejeitar", "description": "..."}
      ],
      "status": "pending",
      "timeout_at": "2024-01-21T10:00:00Z"
    }
  ],
  "total": 1
}
```

---

### Resolver Decisao

<span className="api-method api-method--post">POST</span> `/tron/decisions/{id}/resolve`

**Request Body:**

```json
{
  "selected_option": "opt1",
  "comment": "Aprovado, seguir em frente"
}
```

---

## Directives

Diretivas estrategicas do CIO para guiar os agents.

### Listar Diretivas

<span className="api-method api-method--get">GET</span> `/tron/directives`

**Query Parameters:**

| Param | Tipo |
|-------|------|
| `project_id` | string |
| `active` | bool |

---

### Criar Diretiva

<span className="api-method api-method--post">POST</span> `/tron/directives`

**Request Body:**

```json
{
  "project_id": "65abc123def456789",
  "content": "Priorizar performance sobre novas features",
  "priority": "high",
  "scope": "project",
  "active": true
}
```

**Prioridades:** `low`, `medium`, `high`, `critical`
**Scopes:** `project`, `repo`, `task`

---

## Metrics

### Obter Metricas

<span className="api-method api-method--get">GET</span> `/tron/metrics`

**Query Parameters:**

| Param | Tipo | Default |
|-------|------|---------|
| `project_id` | string | - |
| `days` | int | 7 |

**Response:** `200 OK`

```json
{
  "summary": {
    "total_tasks": 150,
    "completed_tasks": 120,
    "completion_rate": 80.0,
    "total_commits": 450,
    "total_cost_usd": 25.50,
    "avg_daily_cost": 3.64
  },
  "daily": [
    {
      "date": "2024-01-20",
      "tasks_created": 5,
      "tasks_completed": 3,
      "commits": 12,
      "cost_usd": 2.35
    }
  ],
  "by_repo": [
    {
      "repo_id": "65abc123def456790",
      "repo_name": "backend",
      "tasks": 50,
      "commits": 150,
      "health_score": 85
    }
  ],
  "by_agent": [
    {"agent": "board", "runs": 28, "avg_duration_ms": 1500},
    {"agent": "pm", "runs": 28, "avg_duration_ms": 3000},
    {"agent": "dev", "runs": 45, "avg_duration_ms": 120000},
    {"agent": "qa", "runs": 45, "avg_duration_ms": 5000}
  ]
}
```

---

## Agent Logs

### Listar Logs

<span className="api-method api-method--get">GET</span> `/tron/logs`

**Query Parameters:**

| Param | Tipo | Default |
|-------|------|---------|
| `project_id` | string | - |
| `agent_type` | string | - |
| `limit` | int | 50 |
| `offset` | int | 0 |

**Response:** `200 OK`

```json
{
  "logs": [
    {
      "id": "65abc123def456793",
      "agent_type": "dev",
      "action": "implement_task",
      "task_id": "65abc123def456791",
      "input_summary": "Task: Add rate limiting",
      "output_summary": "Created 2 files, modified 1",
      "success": true,
      "duration_ms": 125000,
      "metrics": {
        "tokens_input": 5000,
        "tokens_output": 2000,
        "cost_usd": 0.15
      },
      "created_at": "2024-01-20T18:15:00Z"
    }
  ],
  "total": 500
}
```

---

## WebSocket

### Conectar ao Stream

<span className="api-method api-method--get">WS</span> `/tron/ws`

Conecta ao stream de eventos em tempo real.

**Query Parameters:**

| Param | Tipo | Descricao |
|-------|------|-----------|
| `token` | string | JWT token |

**Eventos recebidos:**

```json
// Task update
{
  "type": "task_update",
  "data": { "task": {...} }
}

// Agent log
{
  "type": "agent_log",
  "data": { "log": {...} }
}

// Cycle started
{
  "type": "cycle_started",
  "data": { "project_id": "...", "cycle_id": "..." }
}

// Cycle completed
{
  "type": "cycle_completed",
  "data": { "project_id": "...", "result": {...} }
}
```

**Exemplo JavaScript:**

```javascript
const ws = new WebSocket('ws://localhost:8080/api/v1/tron/ws?token=' + token);

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Event:', data.type, data.data);
};
```
