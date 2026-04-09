import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/prompt_entity.dart';
import '../repositories/prompt_repository.dart';

class GetTodayPrompt {
  const GetTodayPrompt(this._repository);

  final PromptRepository _repository;

  Future<Either<Failure, PromptEntity?>> call({
    required String coupleId,
    required String date,
  }) =>
      _repository.getTodayPrompt(coupleId: coupleId, date: date);
}
