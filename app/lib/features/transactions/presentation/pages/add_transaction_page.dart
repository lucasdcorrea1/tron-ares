import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_form.dart';

/// Page for adding a new transaction
class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<TransactionBloc, TransactionState>(
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
      child: Scaffold(
        appBar: ImperiumAppBar(
          title: l10n.addTransaction,
          showBackButton: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TransactionForm(
            onSubmit: (transaction) {
              context
                  .read<TransactionBloc>()
                  .add(AddTransactionEvent(transaction));
            },
          ),
        ),
      ),
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
