---
sidebar_position: 1
---

# TRON - Autonomous Software House

TRON e um sistema autonomo de desenvolvimento de software que utiliza agentes de IA para evoluir repositorios automaticamente.

## Conceito

O TRON funciona como uma "software house autonoma" onde agentes de IA colaboram para:
- Analisar codigo existente
- Gerar tasks de desenvolvimento
- Implementar codigo usando Claude Code CLI
- Revisar e aprovar mudancas
- Propagar atualizacoes entre repositorios

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      ORCHESTRATOR                           │
│  Coordena o ciclo completo dos agentes                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  BOARD AGENT  │    │   PM AGENT    │    │  DEV AGENT    │
│  (CTO)        │    │   (Product)   │    │  (Developer)  │
│               │    │               │    │               │
│ Decide qual   │    │ Gera tasks    │    │ Implementa    │
│ repo e tipo   │    │ com specs     │    │ usando Claude │
│ de trabalho   │    │ detalhados    │    │ Code CLI      │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   QA AGENT    │    │  INTEGRATION  │    │   SCHEDULER   │
│               │    │    AGENT      │    │               │
│ Revisa codigo │    │ Propaga       │    │ Executa       │
│ e testes      │    │ mudancas      │    │ ciclos        │
│               │    │ cross-repo    │    │ periodicos    │
└───────────────┘    └───────────────┘    └───────────────┘
```

## Fluxo de Ciclo

1. **Board Agent** analisa o estado do projeto e decide qual repo precisa de trabalho
2. **PM Agent** gera uma task detalhada usando 4 "lentes":
   - Market: tendencias e competidores
   - Expansion: novas features
   - Persona: melhorias UX
   - Code: refatoracao e bugs
3. **Dev Agent** implementa a task usando Claude Code CLI
4. **QA Agent** revisa o codigo (build, tests, linter + AI review)
5. **Integration Agent** propaga mudancas para repos dependentes

## Frequencias

| Frequencia | Execucoes/dia | Cron |
|------------|---------------|------|
| `high` | 8x | A cada 3 horas |
| `normal` | 4x | 6am, 12pm, 6pm, 11pm |
| `low` | 2x | 9am, 9pm |

## Quick Start

```bash
# 1. Criar um projeto TRON
curl -X POST http://localhost:8080/api/v1/tron/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Meu Projeto",
    "description": "Descricao do projeto",
    "frequency": "normal",
    "daily_budget": 5.0
  }'

# 2. Adicionar um repositorio
curl -X POST http://localhost:8080/api/v1/tron/projects/{id}/repos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "github_url": "https://github.com/user/repo",
    "is_main": true
  }'

# 3. Disparar um ciclo manual
curl -X POST http://localhost:8080/api/v1/tron/projects/{id}/cycle \
  -H "Authorization: Bearer $TOKEN"
```

## Configuracao

Variaveis de ambiente necessarias:

| Variavel | Descricao |
|----------|-----------|
| `CLAUDE_API_KEY` | API key do Claude (Anthropic) |
| `GITHUB_TOKEN` | Token do GitHub para operacoes git |

## Monitoramento

- **Grafana Dashboard**: TRON - Autonomous Software House
- **Metricas Prometheus**: `tron_*`
- **WebSocket**: `/api/v1/tron/ws` para updates em tempo real
