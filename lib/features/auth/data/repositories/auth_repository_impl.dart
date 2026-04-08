import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/metrics_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource, this._metrics);

  final AuthRemoteDataSource _dataSource;
  final MetricsService _metrics;

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await _metrics.measure(
        table: 'auth',
        operation: 'sign_in_google',
        action: _dataSource.signInWithGoogle,
      );
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _metrics.measure(
        table: 'auth',
        operation: 'sign_out',
        action: _dataSource.signOut,
      );
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _metrics.measure(
        table: 'users',
        operation: 'select',
        action: _dataSource.getCurrentUser,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(_toUserMessage(e)));
    }
  }

  static String _toUserMessage(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return 'A server error occurred. Please try again.';
    if (e is Exception) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('Exception') && !msg.contains('Error:')) return msg;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
