import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/account_entity.dart';

class AccountCard extends StatelessWidget {
  final ConnectedAccount account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(account.color);
    final provider = BankProviders.getById(account.provider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Bank Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _buildBankIcon(account.provider, color),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Account Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.accountName,
                    style: AppTypography.titleSmall(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        provider?.name ?? account.provider,
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                      if (account.lastFour.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: AppTypography.bodySmall(color: AppColors.textMuted),
                        ),
                        Text(
                          '****${account.lastFour}',
                          style: AppTypography.bodySmall(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildAccountTypeChip(account.accountType),
                      if (!account.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Inativo',
                            style: AppTypography.labelSmall(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatBRL(account.balance),
                  style: AppTypography.titleSmall(
                    color: account.balance >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLastSync(account.lastSync),
                  style: AppTypography.labelSmall(color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankIcon(String provider, Color color) {
    IconData icon;
    switch (provider.toLowerCase()) {
      case 'nubank':
        icon = Icons.account_balance;
        break;
      case 'itau':
        icon = Icons.account_balance;
        break;
      case 'bradesco':
        icon = Icons.account_balance;
        break;
      case 'inter':
        icon = Icons.account_balance;
        break;
      case 'c6':
        icon = Icons.account_balance;
        break;
      case 'picpay':
        icon = Icons.account_balance_wallet;
        break;
      case 'mercadopago':
        icon = Icons.shopping_cart;
        break;
      default:
        icon = Icons.account_balance;
    }
    return Icon(icon, color: color, size: 26);
  }

  Widget _buildAccountTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'checking':
        label = 'Corrente';
        color = AppColors.info;
        break;
      case 'savings':
        label = 'Poupanca';
        color = AppColors.income;
        break;
      case 'credit':
        label = 'Credito';
        color = AppColors.warning;
        break;
      default:
        label = type;
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(color: color),
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return 'Agora';
    } else if (diff.inHours < 1) {
      return 'Ha ${diff.inMinutes}min';
    } else if (diff.inDays < 1) {
      return 'Ha ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Ha ${diff.inDays}d';
    } else {
      return '${lastSync.day}/${lastSync.month}';
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
