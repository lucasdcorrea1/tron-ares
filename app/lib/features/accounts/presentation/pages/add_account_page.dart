import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/account_model.dart';
import '../../domain/entities/account_entity.dart';
import '../bloc/accounts_bloc.dart';
import '../bloc/accounts_event.dart';
import '../bloc/accounts_state.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastFourController = TextEditingController();
  final _balanceController = TextEditingController();

  BankProvider? _selectedProvider;
  String _selectedAccountType = 'checking';

  @override
  void dispose() {
    _nameController.dispose();
    _lastFourController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Conta'),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: BlocListener<AccountsBloc, AccountsState>(
        listener: (context, state) {
          if (state is AccountCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Conta adicionada com sucesso!'),
                backgroundColor: AppColors.income,
              ),
            );
            context.pop();
          } else if (state is AccountsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.expense,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Selection
                Text(
                  'Selecione o Banco',
                  style: AppTypography.titleSmall(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildBankGrid(),
                const SizedBox(height: AppSpacing.lg),

                // Account Type
                Text(
                  'Tipo de Conta',
                  style: AppTypography.titleSmall(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildAccountTypeSelector(),
                const SizedBox(height: AppSpacing.lg),

                // Account Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Conta',
                    hintText: 'Ex: Conta Principal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite um nome para a conta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Last 4 digits
                TextFormField(
                  controller: _lastFourController,
                  decoration: InputDecoration(
                    labelText: 'Ultimos 4 digitos (opcional)',
                    hintText: '1234',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Balance
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: 'Saldo Atual',
                    hintText: '0.00',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o saldo';
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Digite um valor valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) {
                    final isLoading = state is AccountCreating;

                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Adicionar Conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankGrid() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: BankProviders.all.map((provider) {
        final isSelected = _selectedProvider?.id == provider.id;
        final color = _parseColor(provider.color);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedProvider = provider;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.2) : AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.name,
                  style: AppTypography.labelSmall(
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountTypeSelector() {
    final types = [
      ('checking', 'Corrente', Icons.account_balance),
      ('savings', 'Poupanca', Icons.savings),
      ('credit', 'Credito', Icons.credit_card),
    ];

    return Row(
      children: types.map((type) {
        final isSelected = _selectedAccountType == type.$1;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedAccountType = type.$1;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: type != types.last ? AppSpacing.sm : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type.$3,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.$2,
                    style: AppTypography.labelSmall(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _submitForm() {
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um banco'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final balance = double.tryParse(
            _balanceController.text.replaceAll(',', '.'),
          ) ??
          0.0;

      final request = CreateAccountRequest(
        provider: _selectedProvider!.id,
        accountType: _selectedAccountType,
        accountName: _nameController.text,
        lastFour: _lastFourController.text,
        balance: balance,
        color: _selectedProvider!.color,
        icon: _selectedProvider!.icon,
      );

      context.read<AccountsBloc>().add(CreateAccountEvent(request));
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
