# Imperium App - Development Standards

## 1. Sistema de Cores Dinâmicas

**OBRIGATÓRIO**: Todas as telas e widgets DEVEM usar cores dinâmicas do tema. NUNCA usar cores hardcoded.

### Como Usar

```dart
import '../../../../core/constants/app_colors.dart';

// CORRETO - Cores dinâmicas
Container(
  color: AppColors.primary,
  child: Text('Texto', style: TextStyle(color: AppColors.textPrimary)),
)

// ERRADO - Cores hardcoded
Container(
  color: Color(0xFF7C3AED),  // NUNCA FAZER ISSO
  child: Text('Texto', style: TextStyle(color: Colors.white)),
)
```

### Cores Disponíveis

| Variável | Uso |
|----------|-----|
| `AppColors.primary` | Cor principal (botões, destaques) |
| `AppColors.secondary` | Cor secundária |
| `AppColors.accent` | Acentos e realces |
| `AppColors.income` | Valores positivos, receitas |
| `AppColors.expense` | Valores negativos, despesas, erros |
| `AppColors.backgroundDark` | Fundo de telas |
| `AppColors.surfaceDark` | Superfícies elevadas |
| `AppColors.cardDark` | Fundo de cards |
| `AppColors.textPrimary` | Texto principal |
| `AppColors.textSecondary` | Texto secundário |
| `AppColors.textMuted` | Texto discreto |
| `AppColors.divider` | Divisórias |
| `AppColors.border` | Bordas |
| `AppColors.primaryGradient` | Gradiente principal `[primary, secondary]` |
| `AppColors.accentGradient` | Gradiente de acento |

### Aliases (compatibilidade)

```dart
AppColors.imperiumGold     // = primary
AppColors.success          // = income
AppColors.error            // = expense
AppColors.info             // = secondary
```

### Context Extension (opcional, para widgets reativos)

```dart
// Acesso direto
final colors = context.colors;
Container(color: colors.primary)

// Watch para rebuilds automáticos
final colors = context.watchColors();
```

---

## 2. Estrutura de Features

Toda nova feature deve seguir Clean Architecture:

```
lib/features/[feature_name]/
├── data/
│   ├── datasources/
│   │   └── [feature]_remote_datasource.dart
│   ├── models/
│   │   └── [feature]_model.dart
│   └── repositories/
│       └── [feature]_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── [feature]_entity.dart
│   ├── repositories/
│   │   └── [feature]_repository.dart
│   └── usecases/
│       └── [usecase_name].dart
└── presentation/
    ├── bloc/
    │   ├── [feature]_bloc.dart
    │   ├── [feature]_event.dart
    │   └── [feature]_state.dart
    ├── pages/
    │   └── [feature]_page.dart
    └── widgets/
        └── [widget_name].dart
```

---

## 3. Padrão de Páginas

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: ImperiumAppBar(
        title: 'Título',
        showBackButton: true, // se necessário
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Conteúdo aqui
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Padrão de Cards

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.cardDark,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    border: Border.all(
      color: AppColors.divider,
      width: 1,
    ),
  ),
  child: // conteúdo
)
```

---

## 5. Padrão de Botões

```dart
// Botão primário
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
  ),
  child: Text('Ação'),
)

// Botão outline
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: BorderSide(color: AppColors.primary),
  ),
  child: Text('Ação'),
)
```

---

## 6. Padrão de Textos

```dart
// Títulos
Text('Título', style: AppTypography.titleLarge())
Text('Subtítulo', style: AppTypography.titleMedium())
Text('Label', style: AppTypography.titleSmall())

// Corpo
Text('Texto', style: AppTypography.bodyLarge())
Text('Texto', style: AppTypography.bodyMedium())
Text('Texto pequeno', style: AppTypography.bodySmall())

// Com cor customizada
Text('Texto', style: AppTypography.bodyMedium(color: AppColors.textSecondary))
```

---

## 7. Padrão de Loading

```dart
Center(
  child: CircularProgressIndicator(
    color: AppColors.primary,
  ),
)
```

---

## 8. Padrão de Erros

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.error_outline,
        size: 64,
        color: AppColors.expense,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Erro ao carregar dados',
        style: AppTypography.titleMedium(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.lg),
      ElevatedButton(
        onPressed: () => // retry,
        child: Text('Tentar novamente'),
      ),
    ],
  ),
)
```

---

## 9. Padrão de Empty State

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.inbox_outlined,
        size: 64,
        color: AppColors.textMuted,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Nenhum item encontrado',
        style: AppTypography.titleMedium(color: AppColors.textSecondary),
      ),
    ],
  ),
)
```

---

## 10. Padrão de SnackBar

```dart
// Sucesso
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Operação realizada com sucesso'),
    backgroundColor: AppColors.income,
  ),
);

// Erro
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Erro na operação'),
    backgroundColor: AppColors.expense,
  ),
);
```

---

## 11. Padrão de Gradientes

```dart
// Background com gradiente
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.primaryGradient,
    ),
  ),
)
```

---

## 12. Constantes de Espaçamento

```dart
AppSpacing.xs   // 4
AppSpacing.sm   // 8
AppSpacing.md   // 16
AppSpacing.lg   // 24
AppSpacing.xl   // 32
AppSpacing.xxl  // 48

AppSpacing.radiusSm  // 8
AppSpacing.radiusMd  // 12
AppSpacing.radiusLg  // 16
AppSpacing.radiusXl  // 24
```

---

## 13. Navegação

```dart
import 'package:go_router/go_router.dart';

// Push (adiciona na pilha)
context.push('/rota');

// Go (substitui)
context.go('/rota');

// Pop (volta)
context.pop();

// Com parâmetros
context.push('/rota/$id');
```

---

## 14. Regras Importantes

1. **NUNCA** usar `const` com `AppColors` (são dinâmicos)
2. **SEMPRE** importar cores de `app_colors.dart`
3. **SEMPRE** usar `AppSpacing` para espaçamentos
4. **SEMPRE** usar `AppTypography` para textos
5. **SEMPRE** registrar novos BLoCs/Datasources em `injection_container.dart`
6. **SEMPRE** adicionar novas rotas em `app_router.dart`

---

## 15. Checklist para Nova Tela

- [ ] Usa `AppColors.backgroundDark` como cor de fundo
- [ ] Usa `AppColors.cardDark` para cards
- [ ] Usa `AppColors.primary` para elementos de destaque
- [ ] Usa `AppColors.income/expense` para valores financeiros
- [ ] Usa `AppTypography` para todos os textos
- [ ] Usa `AppSpacing` para todos os espaçamentos
- [ ] Não tem cores hardcoded (Color(0x...) ou Colors.xxx)
- [ ] Não usa `const` com cores dinâmicas
- [ ] Registrado em `injection_container.dart` (se tiver BLoC)
- [ ] Rota adicionada em `app_router.dart`
