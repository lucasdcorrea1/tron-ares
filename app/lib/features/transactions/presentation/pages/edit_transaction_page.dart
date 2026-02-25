import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_form.dart';

/// Page for editing an existing transaction
class EditTransactionPage extends StatelessWidget {
  final String transactionId;

  const EditTransactionPage({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getSuccessMessage(l10n, state.message)),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        TransactionEntity? transaction;

        if (state is TransactionLoaded) {
          transaction = state.transactions.firstWhere(
            (t) => t.id == transactionId,
            orElse: () => throw StateError('Transaction not found'),
          );
        }

        return Scaffold(
          appBar: ImperiumAppBar(
            title: l10n.editTransaction,
            showBackButton: true,
          ),
          body: transaction == null
              ? Center(
                  child: Text(
                    l10n.error,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TransactionForm(
                    transaction: transaction,
                    onSubmit: (updatedTransaction) {
                      context
                          .read<TransactionBloc>()
                          .add(UpdateTransactionEvent(updatedTransaction));
                    },
                  ),
                ),
        );
      },
    );
  }

  String _getSuccessMessage(AppLocalizations l10n, String key) {
    switch (key) {
      case 'transactionAdded':
        return l10n.transactionAdded;
      case 'transactionUpdated':
        return l10n.transactionUpdated;
      case 'transactionDeleted':
        return l10n.transactionDeleted;
      default:
        return l10n.success;
    }
  }
}
