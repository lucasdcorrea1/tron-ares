import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/data/datasources/accounts_remote_datasource.dart';
import '../../features/accounts/presentation/bloc/accounts_bloc.dart';
import '../../features/accounts/presentation/bloc/accounts_event.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/add_account_page.dart';
import '../../features/analytics/data/datasources/analytics_remote_datasource.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/analytics/presentation/bloc/analytics_event.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/debts/presentation/pages/debt_detail_page.dart';
import '../../features/debts/presentation/pages/debts_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/theme_customization_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_event.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/presentation/pages/edit_transaction_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/tron/presentation/bloc/tron_agents_bloc.dart';
import '../../features/tron/presentation/bloc/tron_dashboard_bloc.dart';
import '../../features/tron/presentation/bloc/tron_directives_bloc.dart';
import '../../features/tron/presentation/bloc/tron_kanban_bloc.dart';
import '../../features/tron/presentation/bloc/tron_logs_bloc.dart';
import '../../features/tron/presentation/bloc/tron_metrics_bloc.dart';
import '../../features/tron/presentation/bloc/tron_project_bloc.dart';
import '../../features/tron/presentation/bloc/tron_task_detail_bloc.dart';
import '../../features/tron/presentation/pages/tron_agents_page.dart';
import '../../features/tron/presentation/pages/tron_dashboard_page.dart';
import '../../features/tron/presentation/pages/tron_decisions_page.dart';
import '../../features/tron/presentation/pages/tron_directives_page.dart';
import '../../features/tron/presentation/pages/tron_kanban_page.dart';
import '../../features/tron/presentation/pages/tron_logs_page.dart';
import '../../features/tron/presentation/pages/tron_metrics_page.dart';
import '../../features/tron/presentation/pages/tron_onboarding_page.dart';
import '../../features/tron/presentation/pages/tron_settings_page.dart';
import '../../features/tron/presentation/pages/tron_shell_page.dart';
import '../../features/tron/presentation/pages/tron_task_detail_page.dart';
import '../../shared/widgets/imperium_bottom_nav.dart';
import '../di/injection_container.dart';

/// Custom page transition with fade and slide
class FadeSlideTransitionPage<T> extends CustomTransitionPage<T> {
  FadeSlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    Duration duration = const Duration(milliseconds: 250),
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Modal page transition (faster, slides from bottom)
class ModalSlideTransitionPage<T> extends CustomTransitionPage<T> {
  ModalSlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Navigation key for the root navigator
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Navigation key for the shell navigator
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// Navigation key for the TRON shell navigator
final GlobalKey<NavigatorState> _tronShellNavigatorKey =
    GlobalKey<NavigatorState>();

/// App router configuration using go_router
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Login
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => FadeSlideTransitionPage(
          child: BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const LoginPage(),
          ),
        ),
      ),

      // Register
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => ModalSlideTransitionPage(
          child: BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const RegisterPage(),
          ),
        ),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<HomeBloc>()..add(const LoadHomeDataEvent()),
                child: const HomePage(),
              ),
            ),
          ),

          // Transactions list
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) =>
                    sl<TransactionBloc>()..add(const LoadTransactionsEvent()),
                child: const TransactionsPage(),
              ),
            ),
          ),

          // Debts
          GoRoute(
            path: '/debts',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: const DebtsPage(),
            ),
            routes: [
              // Debt detail (nested under /debts)
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ModalSlideTransitionPage(
                    child: DebtDetailPage(debtId: id),
                  );
                },
              ),
            ],
          ),

          // TRON Dashboard (entry point from bottom nav)
          GoRoute(
            path: '/tron',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                      create: (_) => sl<TronProjectBloc>()
                        ..add(const LoadProjectsEvent())),
                  BlocProvider(create: (_) => sl<TronDashboardBloc>()),
                ],
                child: const TronDashboardPage(),
              ),
            ),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: const SettingsPage(),
            ),
          ),
        ],
      ),

      // Add transaction (outside shell for full screen)
      GoRoute(
        path: '/transactions/add',
        pageBuilder: (context, state) => ModalSlideTransitionPage(
          child: BlocProvider(
            create: (_) =>
                sl<TransactionBloc>()..add(const LoadTransactionsEvent()),
            child: const AddTransactionPage(),
          ),
        ),
      ),

      // Edit transaction
      GoRoute(
        path: '/transactions/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return ModalSlideTransitionPage(
            child: BlocProvider(
              create: (_) =>
                  sl<TransactionBloc>()..add(const LoadTransactionsEvent()),
              child: EditTransactionPage(transactionId: id),
            ),
          );
        },
      ),

      // Analytics
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) => ModalSlideTransitionPage(
          child: BlocProvider(
            create: (_) => AnalyticsBloc(
              dataSource: sl<AnalyticsRemoteDataSource>(),
            )..add(const LoadAnalyticsEvent()),
            child: const AnalyticsPage(),
          ),
        ),
      ),

      // Accounts
      GoRoute(
        path: '/accounts',
        pageBuilder: (context, state) => ModalSlideTransitionPage(
          child: BlocProvider(
            create: (_) => AccountsBloc(
              dataSource: sl<AccountsRemoteDataSource>(),
            )..add(const LoadAccountsEvent()),
            child: const AccountsPage(),
          ),
        ),
      ),

      // Add Account
      GoRoute(
        path: '/accounts/add',
        pageBuilder: (context, state) => ModalSlideTransitionPage(
          child: BlocProvider(
            create: (_) => AccountsBloc(
              dataSource: sl<AccountsRemoteDataSource>(),
            ),
            child: const AddAccountPage(),
          ),
        ),
      ),

      // Theme Customization
      GoRoute(
        path: '/settings/theme',
        pageBuilder: (context, state) => ModalSlideTransitionPage(
          child: const ThemeCustomizationPage(),
        ),
      ),

      // TRON Onboarding (outside shell)
      GoRoute(
        path: '/tron/onboarding',
        pageBuilder: (context, state) => FadeSlideTransitionPage(
          child: BlocProvider(
            create: (_) => sl<TronProjectBloc>(),
            child: const TronOnboardingPage(),
          ),
        ),
      ),

      // TRON Shell with sidebar navigation
      ShellRoute(
        navigatorKey: _tronShellNavigatorKey,
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                  create: (_) =>
                      sl<TronProjectBloc>()..add(const LoadProjectsEvent())),
            ],
            child: TronShellPage(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/tron/dashboard',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TronDashboardBloc>(),
                child: const TronDashboardPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/tron/kanban',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TronKanbanBloc>(),
                child: const TronKanbanPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/tron/agents',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TronAgentsBloc>(),
                child: const TronAgentsPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/tron/decisions',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: const TronDecisionsPage(),
            ),
          ),
          GoRoute(
            path: '/tron/directives',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TronDirectivesBloc>(),
                child: const TronDirectivesPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/tron/metrics',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TronMetricsBloc>(),
                child: const TronMetricsPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/tron/logs',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TronLogsBloc>(),
                child: const TronLogsPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/tron/settings',
            pageBuilder: (context, state) => FadeSlideTransitionPage(
              child: const TronSettingsPage(),
            ),
          ),
        ],
      ),

      // TRON Task Detail (outside shell for full screen)
      GoRoute(
        path: '/tron/tasks/:taskId',
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return ModalSlideTransitionPage(
            child: BlocProvider(
              create: (_) => sl<TronTaskDetailBloc>(),
              child: TronTaskDetailPage(taskId: taskId),
            ),
          );
        },
      ),
    ],
  );
}

/// Main shell widget with bottom navigation
class _MainShell extends StatefulWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Update current index based on location
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) {
      _currentIndex = 0;
    } else if (location.startsWith('/transactions')) {
      _currentIndex = 1;
    } else if (location.startsWith('/debts')) {
      _currentIndex = 2;
    } else if (location.startsWith('/tron')) {
      _currentIndex = 3;
    } else if (location.startsWith('/settings')) {
      _currentIndex = 4;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: ImperiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/transactions');
              break;
            case 2:
              context.go('/debts');
              break;
            case 3:
              context.go('/tron');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}
