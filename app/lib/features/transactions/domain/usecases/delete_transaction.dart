import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

/// Use case for deleting a transaction
class DeleteTransactionUseCase implements UseCase<void, String> {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteTransaction(id);
  }
}
