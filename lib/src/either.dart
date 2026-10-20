import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const DeepCollectionEquality _payloadEquality = DeepCollectionEquality();

/// A value that is either an [errorValue] or a [successValue].
///
/// Equality requires the same concrete type (including type arguments) and
/// deeply equal payloads. The payload is stored by reference without copying.
/// Keep it and any nested collections immutable, especially when using an
/// [Either] as a map key or set element.
@immutable
sealed class Either<L, R> {
  /// Whether this instance holds an error value.
  bool get isError => this is EitherError<L, R>;

  /// Whether this instance holds a success value.
  bool get isSuccess => this is EitherSuccess<L, R>;

  /// The error side of [Either].
  L get errorValue => switch (this) {
        EitherError(:final errorValue) => errorValue,
        EitherSuccess() => throw StateError('Either.success has no errorValue'),
      };

  /// The success side of [Either].
  R get successValue => switch (this) {
        EitherSuccess(:final successValue) => successValue,
        EitherError() => throw StateError('Either.error has no successValue'),
      };

  /// Creates an [Either].
  const Either();

  /// Creates an error [Either].
  const factory Either.error(L errorValue) = EitherError<L, R>;

  /// Creates a successful [Either].
  const factory Either.success(R successValue) = EitherSuccess<L, R>;

  /// Applies [onError] or [onSuccess] depending on the held value.
  T fold<T>(
    T Function(L errorValue) onError,
    T Function(R successValue) onSuccess,
  ) {
    return switch (this) {
      EitherError(:final errorValue) => onError(errorValue),
      EitherSuccess(:final successValue) => onSuccess(successValue),
    };
  }

  /// Maps the success value, leaving an error unchanged.
  Either<L, R2> map<R2>(R2 Function(R successValue) transform) {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(errorValue),
      EitherSuccess(:final successValue) => Either.success(transform(successValue)),
    };
  }

  /// Chains a result-returning operation on success, skipping it on error.
  /// Callback exceptions propagate without capture.
  Either<L, R2> andThen<R2>(Either<L, R2> Function(R successValue) transform) {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(errorValue),
      EitherSuccess(:final successValue) => transform(successValue),
    };
  }

  /// Maps the error value, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Either<L2, R> mapError<L2>(L2 Function(L errorValue) transform) {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(transform(errorValue)),
      EitherSuccess(:final successValue) => Either.success(successValue),
    };
  }

  /// Recovers an error with another result, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Either<L, R> recover(Either<L, R> Function(L errorValue) onError) {
    return switch (this) {
      EitherError(:final errorValue) => onError(errorValue),
      EitherSuccess() => this,
    };
  }

  /// Awaits a success transform, leaving an error payload unchanged.
  /// Callback exceptions complete the returned future with that error and trace.
  Future<Either<L, R2>> mapAsync<R2>(FutureOr<R2> Function(R successValue) transform) async {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(errorValue),
      EitherSuccess(:final successValue) => Either.success(await transform(successValue)),
    };
  }

  /// Awaits a result-returning operation on success, skipping it on error.
  /// Callback exceptions propagate without capture.
  Future<Either<L, R2>> andThenAsync<R2>(FutureOr<Either<L, R2>> Function(R successValue) transform) async {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(errorValue),
      EitherSuccess(:final successValue) => await transform(successValue),
    };
  }

  /// Awaits an error transform, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Future<Either<L2, R>> mapErrorAsync<L2>(FutureOr<L2> Function(L errorValue) transform) async {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(await transform(errorValue)),
      EitherSuccess(:final successValue) => Either.success(successValue),
    };
  }

  /// Awaits recovery of an error, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Future<Either<L, R>> recoverAsync(FutureOr<Either<L, R>> Function(L errorValue) onError) async {
    return switch (this) {
      EitherError(:final errorValue) => await onError(errorValue),
      EitherSuccess() => this,
    };
  }
}

/// [Either] that holds an error value.
@immutable
final class EitherError<L, R> extends Either<L, R> {
  @override
  final L errorValue;

  @override
  int get hashCode => Object.hash(runtimeType, _payloadEquality.hash(errorValue));

  /// Creates an error [Either].
  const EitherError(this.errorValue);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is EitherError<L, R> &&
        _payloadEquality.equals(errorValue, other.errorValue) &&
        _payloadEquality.equals(other.errorValue, errorValue);
  }
}

/// [Either] that holds a success value.
@immutable
final class EitherSuccess<L, R> extends Either<L, R> {
  @override
  final R successValue;

  @override
  int get hashCode => Object.hash(runtimeType, _payloadEquality.hash(successValue));

  /// Creates a successful [Either].
  const EitherSuccess(this.successValue);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is EitherSuccess<L, R> &&
        _payloadEquality.equals(successValue, other.successValue) &&
        _payloadEquality.equals(other.successValue, successValue);
  }
}

/// Composes asynchronous results without awaiting between individual steps.
///
/// Only the selected branch callback runs, after this future completes. A failed
/// source future or callback completes the returned future with the original
/// error and stack trace; [recover] handles error payloads, not failed futures.
extension FutureEitherOperations<L, R> on Future<Either<L, R>> {
  /// Awaits a success transform, leaving an error payload unchanged.
  Future<Either<L, R2>> map<R2>(FutureOr<R2> Function(R successValue) transform) =>
      then((result) => result.mapAsync(transform));

  /// Awaits a result-returning operation on success, skipping it on error.
  Future<Either<L, R2>> andThen<R2>(FutureOr<Either<L, R2>> Function(R successValue) transform) =>
      then((result) => result.andThenAsync(transform));

  /// Awaits an error transform, leaving a success payload unchanged.
  Future<Either<L2, R>> mapError<L2>(FutureOr<L2> Function(L errorValue) transform) =>
      then((result) => result.mapErrorAsync(transform));

  /// Awaits recovery of an error, leaving a success payload unchanged.
  Future<Either<L, R>> recover(FutureOr<Either<L, R>> Function(L errorValue) onError) =>
      then((result) => result.recoverAsync(onError));
}
