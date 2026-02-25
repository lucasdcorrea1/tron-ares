import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/animated_fab.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions_list.dart';
import '../../../../shared/widgets/pet_hero_section.dart';

/// Home page / Dashboard
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: ImperiumAppBar(
        title: l10n.appName,
        showLogo: true,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const HomeLoadingSkeleton();
          }

          if (state is HomeError) {
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
                      context.read<HomeBloc>().add(const LoadHomeDataEvent());
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(const RefreshHomeDataEvent());
              },
              color: AppColors.imperiumGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet Hero Section
                    PetHeroSection(
                      stats: PetStats(
                        totalCoins: state.totalBalance.abs(),
                        realBalance: state.totalBalance,
                        savingsBalance: state.monthlyIncome - state.monthlyExpenses,
                        earningsPerTap: 5,
                        currentLeague: 'Bronze',
                        profitPerHour: 12,
                        streakDays: 3,
                        energyPercent: 75,
                        petLevel: 1,
                        energy: 312,
                        maxEnergy: 500,
                        experience: 0.35,
                      ),
                      onPetTap: () {
                        // TODO: Pet interaction
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Monthly Summary
                    MonthlySummaryCard(
                      income: state.monthlyIncome,
                      expenses: state.monthlyExpenses,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Quick Actions
                    const QuickActions(),
                    const SizedBox(height: AppSpacing.lg),

                    // Recent Transactions
                    RecentTransactionsList(
                      transactions: state.recentTransactions,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
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
}
