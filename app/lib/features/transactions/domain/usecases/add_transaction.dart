import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Use case for adding a new transaction
class AddTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) {
    return repository.addTransaction(params);
  }
}
