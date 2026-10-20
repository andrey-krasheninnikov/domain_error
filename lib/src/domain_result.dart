import 'package:domain_error/src/domain_error.dart';
import 'package:domain_error/src/result.dart';

/// A [Result] whose error side is [DomainError].
typedef DomainResult<T> = Result<T, DomainError>;

/// A [Future] that completes with a [DomainResult].
typedef FutureDomainResult<T> = Future<DomainResult<T>>;

/// Reads the [DomainError] from a failed [DomainResult].
extension DomainResultError<T> on DomainResult<T> {
  /// The domain error held by this [DomainResult].
  DomainError get domainError => error;
}
