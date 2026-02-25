# Prompt: Criação do App Imperium — Flutter MVP com Clean Architecture

---

## Contexto

Você é um desenvolvedor Flutter sênior especializado em Clean Architecture e boas práticas. Seu objetivo é criar o MVP do **Imperium**, um aplicativo financeiro pessoal.

## Requisitos Gerais

- **Nome do app:** Imperium
- **Linguagem da interface:** Português do Brasil (pt-BR)
- **Linguagem do código:** 100% em inglês (variáveis, classes, funções, comentários)
- **Internacionalização (i18n):** Preparado para multi-idioma usando `flutter_localizations` + `intl` + arquivos `.arb`. O pt-BR será o idioma padrão, mas a estrutura deve permitir adicionar novos idiomas facilmente.
- **Arquitetura:** Clean Architecture com separação rigorosa de camadas
- **Gerenciamento de estado:** Bloc/Cubit (flutter_bloc)
- **Injeção de dependência:** get_it + injectable
- **Navegação:** go_router
- **Banco de dados local:** drift (SQLite) ou isar
- **Tema:** Dark mode elegante com tons de dourado, preto e cinza escuro — identidade visual premium inspirada no nome "Imperium"

---

## Estrutura de Pastas (Clean Architecture)

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart         // apenas chaves, textos vêm do i18n
│   │   ├── app_spacing.dart
│   │   └── app_typography.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── dark_theme.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── usecases/
│   │   └── usecase.dart             // classe base abstrata
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   └── validators.dart
│   ├── l10n/
│   │   ├── app_localizations.dart
│   │   ├── arb/
│   │   │   ├── app_pt.arb           // Português (padrão)
│   │   │   └── app_en.arb           // Inglês (futuro)
│   │   └── l10n.dart
│   └── di/
│       └── injection_container.dart
│
├── features/
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── onboarding_page.dart
│   │       └── widgets/
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── home_page.dart
│   │       ├── widgets/
│   │       │   ├── balance_card.dart
│   │       │   ├── recent_transactions_list.dart
│   │       │   └── quick_actions.dart
│   │       └── bloc/
│   │           ├── home_bloc.dart
│   │           ├── home_event.dart
│   │           └── home_state.dart
│   │
│   ├── transactions/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── transaction.dart
│   │   │   ├── repositories/
│   │   │   │   └── transaction_repository.dart    // contrato abstrato
│   │   │   └── usecases/
│   │   │       ├── add_transaction.dart
│   │   │       ├── get_transactions.dart
│   │   │       ├── delete_transaction.dart
│   │   │       └── get_balance.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── transaction_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── transaction_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── transaction_repository_impl.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── transactions_page.dart
│   │       │   └── add_transaction_page.dart
│   │       ├── widgets/
│   │       │   ├── transaction_tile.dart
│   │       │   └── transaction_form.dart
│   │       └── bloc/
│   │           ├── transaction_bloc.dart
│   │           ├── transaction_event.dart
│   │           └── transaction_state.dart
│   │
│   └── settings/
│       └── presentation/
│           ├── pages/
│           │   └── settings_page.dart
│           └── widgets/
│
└── shared/
    └── widgets/
        ├── imperium_app_bar.dart
        ├── imperium_button.dart
        ├── imperium_card.dart
        ├── imperium_bottom_nav.dart
        └── imperium_text_field.dart
```

---

## Regras de Código

### Clean Architecture — Camadas

1. **Domain (domínio):** Entidades puras, contratos de repositórios (abstract class), e use cases. ZERO dependência de Flutter ou pacotes externos.

2. **Data (dados):** Implementação dos repositórios, models (com toJson/fromJson/toEntity), e datasources (local/remoto).

3. **Presentation (apresentação):** Pages, Widgets e Blocs/Cubits. A camada de apresentação NUNCA acessa datasources diretamente — sempre passa pelo use case.

### Fluxo de Dados

```
UI (Page) → Bloc/Cubit → UseCase → Repository (contrato) → RepositoryImpl → DataSource
```

### Convenções de Nomenclatura

- Classes: `PascalCase` → `TransactionEntity`, `AddTransactionUseCase`
- Arquivos: `snake_case` → `transaction_entity.dart`, `add_transaction_use_case.dart`
- Variáveis/funções: `camelCase` → `totalBalance`, `getTransactions()`
- Constantes: `camelCase` com prefixo contextual → `AppColors.imperiumGold`
- Blocs: `[Feature]Bloc` / `[Feature]Event` / `[Feature]State`
- Enums: `PascalCase` com valores `camelCase`

### Regras de Internacionalização (i18n)

- Nenhuma string visível ao usuário pode estar hardcoded no código
- Todas as strings devem vir dos arquivos `.arb`
- Acessar via: `AppLocalizations.of(context).nomeDaChave`
- Chaves em inglês no `.arb`: `"transactionAdded": "Transação adicionada com sucesso"`

---

## MVP — Funcionalidades Iniciais

### 1. Splash Screen
- Logo do Imperium com animação sutil
- Verificação de primeiro acesso

### 2. Onboarding (primeiro acesso)
- 3 telas simples apresentando o app
- Botão "Começar" que leva à Home

### 3. Home / Dashboard
- Saldo total (receitas - despesas)
- Card com resumo do mês (total receitas, total despesas)
- Lista das últimas 5 transações
- Botão flutuante para adicionar transação

### 4. Adicionar Transação
- Tipo: Receita ou Despesa (toggle elegante)
- Valor (com máscara de moeda BRL)
- Descrição
- Categoria (lista pré-definida: Alimentação, Transporte, Moradia, Lazer, Saúde, Educação, Salário, Freelance, Outros)
- Data (date picker, padrão hoje)
- Botão salvar

### 5. Lista de Transações
- Filtro por período (mês atual, últimos 7 dias, personalizado)
- Filtro por tipo (receita/despesa/todos)
- Swipe para deletar
- Ordenação por data (mais recente primeiro)

### 6. Configurações
- Alternar tema (dark/light) — padrão dark
- Sobre o app
- Versão

---

## Identidade Visual — Tema Imperium

```dart
// Paleta de cores sugerida
abstract class AppColors {
  // Primary
  static const imperiumGold = Color(0xFFD4AF37);
  static const imperiumDarkGold = Color(0xFFB8960C);

  // Background
  static const backgroundDark = Color(0xFF0D0D0D);
  static const surfaceDark = Color(0xFF1A1A1A);
  static const cardDark = Color(0xFF242424);

  // Text
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF707070);

  // Semantic
  static const income = Color(0xFF4CAF50);
  static const expense = Color(0xFFE53935);

  // Accent
  static const divider = Color(0xFF2A2A2A);
}
```

### Tipografia
- Títulos: `Playfair Display` ou `Cormorant Garamond` (elegância clássica)
- Corpo: `Inter` ou `Poppins` (legibilidade moderna)
- Valores monetários: `JetBrains Mono` ou `Space Mono` (monospace elegante)

---

## Pacotes Recomendados (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  flutter_bloc: ^8.1.0
  equatable: ^2.0.0
  get_it: ^7.6.0
  injectable: ^2.3.0
  go_router: ^14.0.0
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.0
  intl: ^0.19.0
  uuid: ^4.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  injectable_generator: ^2.4.0
  drift_dev: ^2.15.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  flutter_lints: ^4.0.0
```

---

## Exemplo de Entidade (Domain Layer)

```dart
// lib/features/transactions/domain/entities/transaction.dart

import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class TransactionEntity extends Equatable {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, description, amount, type, category, date, createdAt];
}
```

---

## Exemplo de UseCase (Domain Layer)

```dart
// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
```

```dart
// lib/features/transactions/domain/usecases/add_transaction.dart

class AddTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) {
    return repository.addTransaction(params);
  }
}
```

---

## Instruções Finais

1. Gere TODOS os arquivos listados na estrutura de pastas
2. Cada arquivo deve estar completo e funcional
3. O código deve compilar sem erros
4. Siga rigorosamente a Clean Architecture — nenhum atalho entre camadas
5. Todos os textos do usuário devem estar nos arquivos `.arb`
6. Use `Either<Failure, Success>` do pacote `dartz` para tratamento de erros
7. Inclua comentários explicativos nos pontos mais importantes para fins de aprendizado
8. O app deve rodar com `flutter run` após a geração

---

> **Nota:** Este é o MVP. Futuras iterações incluirão: autenticação, sincronização na nuvem, gráficos de gastos, metas financeiras, exportação de relatórios e notificações.
