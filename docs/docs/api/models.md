---
sidebar_position: 2
---

# Models

Documentacao das estruturas de dados utilizadas na API.

---

## User

Representa os dados de autenticacao do usuario.

```go
type User struct {
    ID           ObjectID  `json:"id"`
    Email        string    `json:"email"`
    PasswordHash string    `json:"-"`  // Nunca exposto
    CreatedAt    time.Time `json:"created_at"`
}
```

| Campo | Tipo | Descricao |
|-------|------|-----------|
| `id` | ObjectID | ID unico do usuario |
| `email` | string | Email do usuario (unico) |
| `created_at` | datetime | Data de criacao |

---

## Profile

Representa o perfil do usuario com configuracoes.

```go
type Profile struct {
    ID        ObjectID        `json:"id"`
    UserID    ObjectID        `json:"user_id"`
    Name      string          `json:"name"`
    Avatar    string          `json:"avatar"`
    Bio       string          `json:"bio"`
    Settings  ProfileSettings `json:"settings"`
    CreatedAt time.Time       `json:"created_at"`
    UpdatedAt time.Time       `json:"updated_at"`
}
```

### ProfileSettings

```go
type ProfileSettings struct {
    Currency       string        `json:"currency"`        // "BRL", "USD", etc
    Language       string        `json:"language"`        // "pt-BR", "en-US"
    Theme          ThemeSettings `json:"theme"`
    FirstDayOfWeek int           `json:"first_day_of_week"` // 0=Dom, 1=Seg
    DateFormat     string        `json:"date_format"`     // "DD/MM/YYYY"
}
```

### ThemeSettings

```go
type ThemeSettings struct {
    Mode         string `json:"mode"`          // "dark", "light", "system"
    PrimaryColor string `json:"primary_color"` // Hex: "#D4AF37"
    AccentColor  string `json:"accent_color"`  // Hex: "#E0C563"
}
```

---

## Transaction

Representa uma transacao financeira.

```go
type Transaction struct {
    ID          ObjectID  `json:"id"`
    UserID      ObjectID  `json:"user_id"`
    Description string    `json:"description"`
    Amount      float64   `json:"amount"`
    Type        string    `json:"type"`      // "income" | "expense"
    Category    string    `json:"category"`
    Date        time.Time `json:"date"`
    CreatedAt   time.Time `json:"created_at"`
}
```

### TransactionType

| Valor | Descricao |
|-------|-----------|
| `income` | Receita/Entrada |
| `expense` | Despesa/Saida |

### TransactionCategory

| Categoria | Cor | Descricao |
|-----------|-----|-----------|
| `food` | #FF6B6B | Alimentacao |
| `transport` | #4ECDC4 | Transporte |
| `housing` | #45B7D1 | Moradia |
| `leisure` | #96CEB4 | Lazer |
| `health` | #FFEAA7 | Saude |
| `education` | #DDA0DD | Educacao |
| `salary` | #98D8C8 | Salario |
| `freelance` | #F7DC6F | Freelance |
| `other` | #B0B0B0 | Outros |

---

## ConnectedAccount

Representa uma conta bancaria conectada.

```go
type ConnectedAccount struct {
    ID          ObjectID  `json:"id"`
    UserID      ObjectID  `json:"user_id"`
    Provider    string    `json:"provider"`      // "nubank", "itau", etc
    AccountType string    `json:"account_type"`  // "checking", "savings", "credit"
    AccountName string    `json:"account_name"`
    LastFour    string    `json:"last_four"`     // Ultimos 4 digitos
    Balance     float64   `json:"balance"`
    Color       string    `json:"color"`         // Hex color
    Icon        string    `json:"icon"`
    IsActive    bool      `json:"is_active"`
    LastSync    time.Time `json:"last_sync"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}
```

### BankProviders

| Provider | Nome | Cor |
|----------|------|-----|
| `nubank` | Nubank | #8A05BE |
| `itau` | Itau | #EC7000 |
| `bradesco` | Bradesco | #CC092F |
| `santander` | Santander | #EC0000 |
| `bb` | Banco do Brasil | #FFEF00 |
| `caixa` | Caixa | #005CA9 |
| `inter` | Inter | #FF7A00 |
| `c6` | C6 Bank | #242424 |
| `picpay` | PicPay | #21C25E |
| `mercadopago` | Mercado Pago | #00B1EA |

---

## ProfileStats

Estatisticas do perfil para dashboards.

```go
type ProfileStats struct {
    TotalBalance        float64             `json:"total_balance"`
    MonthlyIncome       float64             `json:"monthly_income"`
    MonthlyExpenses     float64             `json:"monthly_expenses"`
    MonthlySavings      float64             `json:"monthly_savings"`
    TransactionCount    int64               `json:"transaction_count"`
    TopCategories       []CategoryStat      `json:"top_categories"`
    MonthlyTrend        []MonthlyTrendPoint `json:"monthly_trend"`
    ExpensesByCategory  []CategoryStat      `json:"expenses_by_category"`
    ComparisonLastMonth ComparisonStats     `json:"comparison_last_month"`
    ConnectedAccounts   int                 `json:"connected_accounts"`
}
```

### CategoryStat

```go
type CategoryStat struct {
    Category   string  `json:"category"`
    Amount     float64 `json:"amount"`
    Percentage float64 `json:"percentage"`
    Color      string  `json:"color"`
}
```

### MonthlyTrendPoint

```go
type MonthlyTrendPoint struct {
    Month    string  `json:"month"`    // "2024-01"
    Income   float64 `json:"income"`
    Expenses float64 `json:"expenses"`
    Balance  float64 `json:"balance"`
}
```

### ComparisonStats

```go
type ComparisonStats struct {
    IncomeChange  float64 `json:"income_change"`   // % mudanca
    ExpenseChange float64 `json:"expense_change"`  // % mudanca
    SavingsChange float64 `json:"savings_change"`  // % mudanca
}
```

---

## BalanceResponse

Resposta do endpoint de saldo.

```go
type BalanceResponse struct {
    Balance       float64 `json:"balance"`
    TotalIncome   float64 `json:"total_income"`
    TotalExpenses float64 `json:"total_expenses"`
}
```
