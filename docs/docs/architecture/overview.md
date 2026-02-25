---
sidebar_position: 1
---

# Visao Geral da Arquitetura

O backend segue uma arquitetura em camadas para garantir separacao de responsabilidades.

## Estrutura de Pastas

```
backend/
├── api/           # Especificacoes da API
├── cmd/           # Ponto de entrada da aplicacao
├── internal/      # Codigo interno da aplicacao
│   ├── handlers/  # Handlers HTTP
│   ├── services/  # Logica de negocio
│   ├── repository/# Acesso a dados
│   └── models/    # Modelos de dados
├── docs/          # Documentacao Swagger
└── monitoring/    # Configuracoes de monitoramento
```

## Fluxo de Dados

1. **Request** -> Handler
2. **Handler** -> Service
3. **Service** -> Repository
4. **Repository** -> Database
