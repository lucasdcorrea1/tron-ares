import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/imperium_button.dart';
import '../../../../shared/widgets/imperium_text_field.dart';
import '../../domain/entities/transaction_entity.dart';

/// Form widget for adding/editing transactions
class TransactionForm extends StatefulWidget {
  final TransactionEntity? transaction;
  final Function(TransactionEntity) onSubmit;

  const TransactionForm({
    super.key,
    this.transaction,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedCategory;
  late DateTime _selectedDate;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _descriptionController.text = widget.transaction!.description;
      _amountController.text =
          CurrencyFormatter.formatBRLWithoutSymbol(widget.transaction!.amount);
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    } else {
      _selectedType = TransactionType.expense;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = CurrencyFormatter.parseBRL(_amountController.text) ?? 0.0;

      final transaction = TransactionEntity(
        id: widget.transaction?.id ?? const Uuid().v4(),
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: _selectedCategory ?? 'other',
        date: _selectedDate,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );

      widget.onSubmit(transaction);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.imperiumGold,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Transaction Type Toggle
          _buildTypeToggle(l10n),
          const SizedBox(height: AppSpacing.lg),

          // Amount Field
          ImperiumTextField(
            controller: _amountController,
            label: l10n.transactionValue,
            hint: 'R\$ 0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            prefixIcon: Icons.attach_money,
            validator: (value) => Validators.positiveNumber(value),
          ),
          const SizedBox(height: AppSpacing.md),

          // Description Field
          ImperiumTextField(
            controller: _descriptionController,
            label: l10n.transactionDescription,
            hint: l10n.transactionDescription,
            prefixIcon: Icons.description_outlined,
            validator: (value) => Validators.required(value),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category Dropdown
          _buildCategoryDropdown(l10n),
          const SizedBox(height: AppSpacing.md),

          // Date Picker
          _buildDatePicker(l10n),
          const SizedBox(height: AppSpacing.xl),

          // Submit Button
          ImperiumButton(
            label: l10n.save,
            onPressed: _submitForm,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _TypeToggleButton(
              label: l10n.expense,
              isSelected: _selectedType == TransactionType.expense,
              color: AppColors.expense,
              onTap: () {
                setState(() {
                  _selectedType = TransactionType.expense;
                  _selectedCategory = null;
                });
              },
            ),
          ),
          Expanded(
            child: _TypeToggleButton(
              label: l10n.income,
              isSelected: _selectedType == TransactionType.income,
              color: AppColors.income,
              onTap: () {
                setState(() {
                  _selectedType = TransactionType.income;
                  _selectedCategory = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n) {
    final categories = _selectedType == TransactionType.income
        ? [
            TransactionCategory.salary,
            TransactionCategory.freelance,
            TransactionCategory.other,
          ]
        : [
            TransactionCategory.food,
            TransactionCategory.transport,
            TransactionCategory.housing,
            TransactionCategory.leisure,
            TransactionCategory.health,
            TransactionCategory.education,
            TransactionCategory.other,
          ];

    String getCategoryName(TransactionCategory category) {
      switch (category) {
        case TransactionCategory.food:
          return l10n.categoryFood;
        case TransactionCategory.transport:
          return l10n.categoryTransport;
        case TransactionCategory.housing:
          return l10n.categoryHousing;
        case TransactionCategory.leisure:
          return l10n.categoryLeisure;
        case TransactionCategory.health:
          return l10n.categoryHealth;
        case TransactionCategory.education:
          return l10n.categoryEducation;
        case TransactionCategory.salary:
          return l10n.categorySalary;
        case TransactionCategory.freelance:
          return l10n.categoryFreelance;
        case TransactionCategory.other:
          return l10n.categoryOther;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transactionCategory,
          style: AppTypography.labelMedium(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l10n.validationSelectCategory,
                  style: AppTypography.bodyMedium(color: AppColors.textMuted),
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              items: categories.map((category) {
                final categoryColor = Color(category.colorValue);
                return DropdownMenuItem(
                  value: category.value,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                              color: categoryColor,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          getCategoryName(category),
                          style: AppTypography.bodyMedium(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transactionDate,
          style: AppTypography.labelMedium(),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                  style: AppTypography.bodyMedium(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge(
              color: isSelected ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
