---
sidebar_position: 2
---

# Deployment

## Docker

O backend pode ser deployado usando Docker:

```bash
docker build -t imperium-backend .
docker run -p 8080:8080 imperium-backend
```

## Variaveis de Ambiente

Configure as seguintes variaveis em producao:

| Variavel | Descricao |
|----------|-----------|
| `DATABASE_URL` | URL de conexao com o PostgreSQL |
| `JWT_SECRET` | Chave secreta para JWT |
| `PORT` | Porta do servidor (default: 8080) |
