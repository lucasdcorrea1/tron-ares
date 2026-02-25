---
sidebar_position: 3
---

# TRON Agents

Documentacao detalhada de cada agente do sistema TRON.

## Board Agent (CTO)

O Board Agent atua como CTO virtual, tomando decisoes estrategicas sobre o projeto.

### Responsabilidades

- Analisar o estado atual de todos os repositorios
- Decidir qual repo precisa de mais atencao
- Escolher o tipo de trabalho a ser feito
- Considerar diretivas do CIO (usuario)

### Tipos de Trabalho

| Tipo | Descricao |
|------|-----------|
| `feature` | Novas funcionalidades |
| `bugfix` | Correcao de bugs |
| `refactor` | Melhoria de codigo |
| `docs` | Documentacao |
| `test` | Adicionar testes |
| `security` | Melhorias de seguranca |

### Input

- Lista de repos com estado atual
- Health score de cada repo
- Tasks pendentes
- Diretivas ativas

### Output

```json
{
  "target_repo": "backend",
  "work_type": "feature",
  "reasoning": "Backend tem health score baixo e precisa de novas features",
  "priority": "high"
}
```

---

## PM Agent (Product Manager)

O PM Agent gera tasks detalhadas com especificacoes completas.

### Responsabilidades

- Analisar o repo alvo
- Gerar tasks usando 4 "lentes" de analise
- Criar specs detalhadas para o Dev Agent
- Definir criterios de aceitacao

### 4 Lentes de Analise

#### 1. Market Lens
Analisa tendencias de mercado e competidores.
- O que competidores estao fazendo?
- Quais features sao esperadas pelo mercado?
- Trends tecnologicos relevantes

#### 2. Expansion Lens
Foca em expandir funcionalidades existentes.
- Quais features podem ser estendidas?
- Integrações novas possiveis
- Melhorias de escalabilidade

#### 3. Persona Lens
Considera a experiencia do usuario.
- Pontos de friccao na UX
- Feedback comum de usuarios
- Acessibilidade e usabilidade

#### 4. Code Lens
Analisa a qualidade tecnica do codigo.
- Code smells e tech debt
- Performance bottlenecks
- Cobertura de testes
- Seguranca

### Output (Task Spec)

```json
{
  "title": "Adicionar rate limiting na API",
  "description": "Implementar rate limiting para proteger a API",
  "source_lens": "code",
  "priority": "high",
  "size": "medium",
  "spec": {
    "what": "Implementar rate limiting usando token bucket algorithm...",
    "why": "Proteger a API contra abuse e DDoS",
    "files_to_create": [
      "internal/middleware/ratelimit.go",
      "internal/middleware/ratelimit_test.go"
    ],
    "files_to_modify": [
      "internal/router/router.go"
    ],
    "acceptance_criteria": [
      "Rate limit de 100 requests/minuto por IP",
      "Header X-RateLimit-Remaining retornado",
      "Status 429 quando limite excedido",
      "Testes unitarios cobrindo casos principais"
    ],
    "edge_cases": [
      "IPs em whitelist nao devem ser limitados",
      "Endpoints de health check sao isentos"
    ]
  }
}
```

---

## Dev Agent (Developer)

O Dev Agent implementa tasks usando Claude Code CLI.

### Responsabilidades

- Receber task spec do PM Agent
- Criar branch para a task
- Implementar usando Claude Code
- Rodar build e testes
- Fazer commits e push

### Fluxo de Execucao

```
1. Clone/pull do repo
2. Criar branch: feat/{task-id}-{slug}
3. Executar Claude Code CLI com prompt
4. Rodar build
5. Rodar testes
6. Se falhar: tentar corrigir (max 3 tentativas)
7. Commit das mudancas
8. Push da branch
```

### Prompt para Claude Code

```
You are the developer for this project. Implement the following task:

TASK: {title}
DESCRIPTION: {description}

SPECIFICATION:
{spec.what}

FILES TO CREATE: {spec.files_to_create}
FILES TO MODIFY: {spec.files_to_modify}

ACCEPTANCE CRITERIA:
{spec.acceptance_criteria}

EDGE CASES TO HANDLE:
{spec.edge_cases}

RULES:
- Follow the project's existing patterns and CLAUDE.md if present
- Make small, focused commits
- Run build and tests before finishing
- Don't modify files outside the scope of this task
```

### Retry Logic

- Max 3 tentativas
- Se build falhar: envia erro para Claude corrigir
- Se testes falharem: envia output para Claude corrigir
- Se todas tentativas falharem: task vai para status `rejected`

---

## QA Agent (Quality Assurance)

O QA Agent revisa o codigo implementado.

### Responsabilidades

- Rodar checks automatizados (build, tests, linter)
- Fazer review de codigo com AI
- Aprovar, solicitar mudancas ou rejeitar

### Checks Automatizados

| Check | Go | TypeScript | Python |
|-------|-----|------------|--------|
| Build | `go build ./...` | `npm run build` | - |
| Tests | `go test ./...` | `npm test` | `pytest` |
| Linter | `golangci-lint run` | `npm run lint` | - |

### Review Checklist

1. O codigo implementa o que a spec pede?
2. Segue os patterns do projeto?
3. Existem edge cases nao tratados?
4. Existem bugs obvios?
5. Existe codigo morto ou desnecessario?
6. Os testes sao significativos?
7. Os nomes sao claros e descritivos?
8. O error handling e adequado?

### Resultados Possiveis

| Resultado | Descricao | Acao |
|-----------|-----------|------|
| `APPROVED` | Codigo OK | Task -> Done |
| `NEEDS_FIX` | Pequenos problemas | Task -> Ready (volta pro Dev) |
| `REJECTED` | Problemas graves | Task -> Rejected (apos 3 tentativas) |

### Output

```json
{
  "result": "NEEDS_FIX",
  "feedback": "Falta tratamento de erro no caso X",
  "issues": [
    {
      "file": "internal/middleware/ratelimit.go",
      "line": 42,
      "issue": "Erro nao tratado ao parsear IP",
      "severity": "minor"
    }
  ],
  "checks": {
    "build_passed": true,
    "tests_passed": true,
    "linter_clean": false
  }
}
```

---

## Integration Agent

O Integration Agent propaga mudancas entre repositorios dependentes.

### Responsabilidades

- Detectar dependencias entre repos
- Identificar mudancas que afetam outros repos
- Gerar tasks de atualizacao para repos dependentes

### Cenarios de Integracao

1. **API Change**: Backend muda endpoint -> Frontend precisa atualizar
2. **Shared Types**: Types mudam -> Todos consumers precisam atualizar
3. **Version Bump**: Package atualiza -> Dependentes precisam atualizar go.mod/package.json

### Output

```json
{
  "updates": [
    {
      "target_repo": "frontend",
      "tasks": [
        {
          "title": "Atualizar chamada do endpoint /users",
          "description": "Endpoint mudou de GET para POST",
          "priority": "high"
        }
      ]
    }
  ]
}
```

---

## Orchestrator

O Orchestrator coordena a execucao de todos os agents em um ciclo.

### Ciclo Completo

```
1. Carregar projeto e repos
2. Verificar budget diario
3. Board Agent decide o plano
4. PM Agent gera task (se Board indicou)
5. Dev Agent implementa tasks ready
6. QA Agent revisa tasks in_review
7. Integration Agent propaga mudancas (se houve completions)
8. Atualizar metricas
```

### Controle de Budget

- Cada projeto tem `daily_budget` em USD
- Orchestrator soma custos de cada agent
- Para execucao se budget for atingido
- Reset do contador a meia-noite

### Timeout

- Ciclo tem timeout de 30 minutos
- Agents individuais tem timeouts menores
- Se timeout: ciclo e interrompido, estado e salvo
