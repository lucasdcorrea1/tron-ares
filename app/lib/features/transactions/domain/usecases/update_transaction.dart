import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Use case for updating an existing transaction
class UpdateTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) {
    return repository.updateTransaction(params);
  }
}
