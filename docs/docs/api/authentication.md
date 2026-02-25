---
sidebar_position: 3
---

# Autenticacao

O Imperium utiliza **JWT (JSON Web Tokens)** para autenticacao.

## Fluxo de Autenticacao

```
┌──────────┐         ┌──────────┐         ┌──────────┐
│  Cliente │         │   API    │         │ MongoDB  │
└────┬─────┘         └────┬─────┘         └────┬─────┘
     │                    │                    │
     │ POST /auth/login   │                    │
     │ {email, password}  │                    │
     │───────────────────>│                    │
     │                    │  Find user         │
     │                    │───────────────────>│
     │                    │                    │
     │                    │  User data         │
     │                    │<───────────────────│
     │                    │                    │
     │                    │ Verify password    │
     │                    │ Generate JWT       │
     │                    │                    │
     │ {user, token}      │                    │
     │<───────────────────│                    │
     │                    │                    │
     │ GET /api/v1/...    │                    │
     │ Authorization:     │                    │
     │ Bearer <token>     │                    │
     │───────────────────>│                    │
     │                    │                    │
     │                    │ Validate JWT       │
     │                    │ Extract userID     │
     │                    │                    │
     │ Response           │                    │
     │<───────────────────│                    │
     │                    │                    │
```

## JWT Token

### Estrutura do Token

O token JWT contem as seguintes claims:

```json
{
  "user_id": "65abc123def456789",
  "email": "usuario@email.com",
  "exp": 1705320000,
  "iat": 1704715200,
  "iss": "imperium-api"
}
```

| Claim | Descricao |
|-------|-----------|
| `user_id` | ID do usuario no MongoDB |
| `email` | Email do usuario |
| `exp` | Data de expiracao (Unix timestamp) |
| `iat` | Data de emissao (Unix timestamp) |
| `iss` | Emissor do token |

### Configuracao

| Variavel | Default | Descricao |
|----------|---------|-----------|
| `JWT_SECRET` | - | Chave secreta para assinatura |
| `JWT_EXPIRY` | `168h` | Tempo de expiracao (7 dias) |

:::danger Importante
**Nunca** compartilhe ou exponha o `JWT_SECRET` em producao.
:::

## Usando o Token

### Header de Autorizacao

Todas as rotas protegidas requerem o header `Authorization`:

```http
GET /api/v1/profile HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Exemplo com cURL

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@email.com","password":"senha123"}' \
  | jq -r '.token')

# Usar o token
curl -X GET http://localhost:8080/api/v1/profile \
  -H "Authorization: Bearer $TOKEN"
```

### Exemplo com JavaScript

```javascript
// Login
const response = await fetch('/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password })
});
const { token } = await response.json();

// Armazenar token
localStorage.setItem('token', token);

// Usar em requisicoes
const profile = await fetch('/api/v1/profile', {
  headers: { 'Authorization': `Bearer ${token}` }
});
```

### Exemplo com Dart/Flutter

```dart
// Login
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);
final token = jsonDecode(response.body)['token'];

// Usar em requisicoes
final profile = await http.get(
  Uri.parse('$baseUrl/api/v1/profile'),
  headers: {'Authorization': 'Bearer $token'},
);
```

## Erros de Autenticacao

| Status | Mensagem | Causa |
|--------|----------|-------|
| `401` | Authorization header required | Header ausente |
| `401` | Invalid authorization format | Formato incorreto |
| `401` | Invalid or expired token | Token invalido ou expirado |
| `401` | Invalid user ID in token | Token corrompido |

## Seguranca

### Senha

- Minimo 6 caracteres
- Hash com **bcrypt** (cost 12)
- Nunca armazenada em texto plano

### Boas Praticas

1. **Armazene tokens de forma segura** - Use `SecureStorage` em mobile
2. **Renove tokens antes de expirar** - Implemente refresh token
3. **Use HTTPS em producao** - Proteja tokens em transito
4. **Invalide tokens no logout** - Implemente blacklist se necessario
