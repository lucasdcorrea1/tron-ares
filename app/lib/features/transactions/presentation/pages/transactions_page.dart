import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/animated_fab.dart';
import '../../../../shared/widgets/animated_list_item.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_tile.dart';

/// Page displaying all transactions with filters
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: ImperiumAppBar(
        title: l10n.transactionsTitle,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const TransactionsLoadingSkeleton();
          }

          if (state is TransactionError) {
            return Center(
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
                    state.message,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      context
                          .read<TransactionBloc>()
                          .add(const LoadTransactionsEvent());
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state is TransactionLoaded) {
            return Column(
              children: [
                // Filters
                _buildFilters(context, l10n, state),

                // Transaction list
                Expanded(
                  child: state.filteredTransactions.isEmpty
                      ? _buildEmptyState(l10n)
                      : _buildTransactionList(context, l10n, state),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => context.push('/transactions/add'),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    AppLocalizations l10n,
    TransactionLoaded state,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Date filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.filterAll,
                  isSelected: state.dateFilter == DateFilterType.all,
                  onTap: () {
                    context.read<TransactionBloc>().add(
                          const SetDateFilterEvent(
                              filterType: DateFilterType.all),
                        );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterCurrentMonth,
                  isSelected: state.dateFilter == DateFilterType.currentMonth,
                  onTap: () {
                    context.read<TransactionBloc>().add(
                          const SetDateFilterEvent(
                              filterType: DateFilterType.currentMonth),
                        );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterLast7Days,
                  isSelected: state.dateFilter == DateFilterType.last7Days,
                  onTap: () {
                    context.read<TransactionBloc>().add(
                          const SetDateFilterEvent(
                              filterType: DateFilterType.last7Days),
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeFilterChip(
                  label: l10n.filterAll,
                  isSelected: state.filterType == null,
                  onTap: () {
                    context.read<TransactionBloc>().add(
                          const SetFilterTypeEvent(null),
                        );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _TypeFilterChip(
                  label: l10n.incomes,
                  isSelected: state.filterType == TransactionType.income,
                  color: AppColors.income,
                  onTap: () {
                    context.read<TransactionBloc>().add(
                          const SetFilterTypeEvent(TransactionType.income),
                        );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _TypeFilterChip(
                  label: l10n.expenses,
                  isSelected: state.filterType == TransactionType.expense,
                  color: AppColors.expense,
                  onTap: () {
                    context.read<TransactionBloc>().add(
                          const SetFilterTypeEvent(TransactionType.expense),
                        );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noTransactions,
              style: AppTypography.titleMedium(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noTransactionsHint,
              style: AppTypography.bodySmall(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    AppLocalizations l10n,
    TransactionLoaded state,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.filteredTransactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final transaction = state.filteredTransactions[index];
        return AnimatedListItem(
          index: index,
          child: TransactionTile(
            transaction: transaction,
            onTap: () => context.push('/transactions/edit/${transaction.id}'),
            onDelete: () => _showDeleteDialog(context, l10n, transaction),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AppLocalizations l10n,
    TransactionEntity transaction,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          l10n.delete,
          style: AppTypography.titleLarge(),
        ),
        content: Text(
          l10n.deleteTransactionConfirm,
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<TransactionBloc>()
                  .add(DeleteTransactionEvent(transaction.id));
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.imperiumGold.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.imperiumGold : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: isSelected ? AppColors.imperiumGold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.imperiumGold;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.2) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: isSelected ? chipColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
