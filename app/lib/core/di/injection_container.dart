import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../../features/accounts/data/datasources/accounts_remote_datasource.dart';
import '../../features/analytics/data/datasources/analytics_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/debts/data/datasources/debt_local_datasource.dart';
import '../../features/debts/presentation/bloc/debt_bloc.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/schedule/data/datasources/schedule_local_datasource.dart';
import '../../features/schedule/presentation/bloc/schedule_bloc.dart';
import '../../features/settings/presentation/bloc/theme_cubit.dart';
import '../../features/transactions/data/datasources/transaction_remote_datasource.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/domain/usecases/add_transaction.dart';
import '../../features/transactions/domain/usecases/delete_transaction.dart';
import '../../features/transactions/domain/usecases/get_balance.dart';
import '../../features/transactions/domain/usecases/get_transactions.dart';
import '../../features/transactions/domain/usecases/update_transaction.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../../features/tron/data/services/tron_api_service.dart';
import '../../features/tron/data/services/tron_websocket_service.dart';
import '../../features/tron/presentation/bloc/tron_agents_bloc.dart';
import '../../features/tron/presentation/bloc/tron_dashboard_bloc.dart';
import '../../features/tron/presentation/bloc/tron_directives_bloc.dart';
import '../../features/tron/presentation/bloc/tron_kanban_bloc.dart';
import '../../features/tron/presentation/bloc/tron_logs_bloc.dart';
import '../../features/tron/presentation/bloc/tron_metrics_bloc.dart';
import '../../features/tron/presentation/bloc/tron_project_bloc.dart';
import '../../features/tron/presentation/bloc/tron_task_detail_bloc.dart';

/// Service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ==================== Core ====================

  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // API Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // ==================== Auth Feature ====================

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      apiClient: sl(),
    ),
  );

  // Blocs
  sl.registerFactory(
    () => AuthBloc(repository: sl()),
  );

  // ==================== Features ====================

  // --- Transactions Feature ---

  // Data sources (using API)
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByTypeUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetBalanceUseCase(sl()));
  sl.registerLazySingleton(() => GetTotalIncomeUseCase(sl()));
  sl.registerLazySingleton(() => GetTotalExpensesUseCase(sl()));
  sl.registerLazySingleton(() => GetMonthlyIncomeUseCase(sl()));
  sl.registerLazySingleton(() => GetMonthlyExpensesUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => TransactionBloc(
      getTransactions: sl(),
      getTransactionsByType: sl(),
      getTransactionsByDateRange: sl(),
      addTransaction: sl(),
      updateTransaction: sl(),
      deleteTransaction: sl(),
    ),
  );

  // --- Home Feature ---
  sl.registerFactory(
    () => HomeBloc(
      getBalance: sl(),
      getMonthlyIncome: sl(),
      getMonthlyExpenses: sl(),
      getRecentTransactions: sl(),
    ),
  );

  // --- Settings Feature ---
  sl.registerLazySingleton(() => ThemeCubit());

  // --- Debts Feature ---

  // Data sources
  sl.registerLazySingleton<DebtLocalDataSource>(
    () => DebtLocalDataSourceImpl(sl()),
  );

  // Blocs
  sl.registerFactory(
    () => DebtBloc(sl()),
  );

  // --- Schedule Feature ---

  // Data sources
  sl.registerLazySingleton<ScheduleLocalDataSource>(
    () => ScheduleLocalDataSourceImpl(sl()),
  );

  // Blocs
  sl.registerFactory(
    () => ScheduleBloc(sl()),
  );

  // --- Analytics Feature ---
  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // --- Accounts Feature ---
  sl.registerLazySingleton<AccountsRemoteDataSource>(
    () => AccountsRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ==================== TRON Feature ====================

  // Services
  sl.registerLazySingleton<TronApiService>(
    () => TronApiService(apiClient: sl()),
  );

  sl.registerLazySingleton<TronWebSocketService>(
    () => TronWebSocketService(),
  );

  // Blocs
  sl.registerFactory(
    () => TronProjectBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronDashboardBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronKanbanBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronTaskDetailBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronAgentsBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronDirectivesBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronMetricsBloc(apiService: sl()),
  );

  sl.registerFactory(
    () => TronLogsBloc(apiService: sl(), wsService: sl()),
  );
}
