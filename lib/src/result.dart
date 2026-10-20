import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const DeepCollectionEquality _payloadEquality = DeepCollectionEquality();

// Collection equality can depend on operand order, so compare both directions.
bool _payloadsEqual(Object? first, Object? second) =>
    _payloadEquality.equals(first, second) && _payloadEquality.equals(second, first);

/// A value that is either an [error] or a [value].
///
/// Equality requires the same concrete type (including type arguments) and
/// deeply equal payloads. The payload is stored by reference without copying.
/// Keep it and any nested collections immutable, especially when using an
/// [Result] as a map key or set element.
@immutable
sealed class Result<T, E> {
  /// Whether this instance holds an error value.
  bool get isError => this is ResultError<T, E>;

  /// Whether this instance holds a success value.
  bool get isSuccess => this is ResultSuccess<T, E>;

  /// The error side of [Result].
  E get error => switch (this) {
        ResultError(:final error) => error,
        ResultSuccess() => throw StateError('Either.success has no errorValue'),
      };

  /// The success side of [Result].
  T get value => switch (this) {
        ResultSuccess(:final value) => value,
        ResultError() => throw StateError('Either.error has no successValue'),
      };

  /// Creates a [Result].
  const Result();

  /// Creates an error [Result].
  const factory Result.error(E error) = ResultError<T, E>;

  /// Creates a successful [Result].
  const factory Result.success(T value) = ResultSuccess<T, E>;

  /// Applies [onError] or [onSuccess] depending on the held value.
  U fold<U>(
    U Function(E error) onError,
    U Function(T value) onSuccess,
  ) {
    return switch (this) {
      ResultError(:final error) => onError(error),
      ResultSuccess(:final value) => onSuccess(value),
    };
  }

  /// Maps the success value, leaving an error unchanged.
  Result<U, E> map<U>(U Function(T value) transform) {
    return switch (this) {
      ResultError(:final error) => Result.error(error),
      ResultSuccess(:final value) => Result.success(transform(value)),
    };
  }

  /// Chains a result-returning operation on success, skipping it on error.
  /// Callback exceptions propagate without capture.
  Result<U, E> andThen<U>(Result<U, E> Function(T value) transform) {
    return switch (this) {
      ResultError(:final error) => Result.error(error),
      ResultSuccess(:final value) => transform(value),
    };
  }

  /// Maps the error value, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return switch (this) {
      ResultError(:final error) => Result.error(transform(error)),
      ResultSuccess(:final value) => Result.success(value),
    };
  }

  /// Recovers an error with another result, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Result<T, E> recover(Result<T, E> Function(E error) onError) {
    return switch (this) {
      ResultError(:final error) => onError(error),
      ResultSuccess() => this,
    };
  }

  /// Awaits a success transform, leaving an error payload unchanged.
  /// Callback exceptions complete the returned future with that error and trace.
  Future<Result<U, E>> mapAsync<U>(FutureOr<U> Function(T value) transform) async {
    return switch (this) {
      ResultError(:final error) => Result.error(error),
      ResultSuccess(:final value) => Result.success(await transform(value)),
    };
  }

  /// Awaits a result-returning operation on success, skipping it on error.
  /// Callback exceptions propagate without capture.
  Future<Result<U, E>> andThenAsync<U>(FutureOr<Result<U, E>> Function(T value) transform) async {
    return switch (this) {
      ResultError(:final error) => Result.error(error),
      ResultSuccess(:final value) => await transform(value),
    };
  }

  /// Awaits an error transform, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Future<Result<T, F>> mapErrorAsync<F>(FutureOr<F> Function(E error) transform) async {
    return switch (this) {
      ResultError(:final error) => Result.error(await transform(error)),
      ResultSuccess(:final value) => Result.success(value),
    };
  }

  /// Awaits recovery of an error, leaving a success payload unchanged.
  /// Callback exceptions propagate without capture.
  Future<Result<T, E>> recoverAsync(FutureOr<Result<T, E>> Function(E error) onError) async {
    return switch (this) {
      ResultError(:final error) => await onError(error),
      ResultSuccess() => this,
    };
  }
}

/// [Result] that holds an error value.
@immutable
final class ResultError<T, E> extends Result<T, E> {
  @override
  final E error;

  @override
  int get hashCode => Object.hash(runtimeType, _payloadEquality.hash(error));

  /// Creates an error [Result].
  const ResultError(this.error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType && other is ResultError<T, E> && _payloadsEqual(error, other.error);
  }
}

/// [Result] that holds a success value.
@immutable
final class ResultSuccess<T, E> extends Result<T, E> {
  @override
  final T value;

  @override
  int get hashCode => Object.hash(runtimeType, _payloadEquality.hash(value));

  /// Creates a successful [Result].
  const ResultSuccess(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType && other is ResultSuccess<T, E> && _payloadsEqual(value, other.value);
  }
}

/// Composes asynchronous results without awaiting between individual steps.
///
/// Only the selected branch callback runs, after this future completes. A failed
/// source future or callback completes the returned future with the original
/// error and stack trace; [recover] handles error payloads, not failed futures.
extension FutureResult<T, E> on Future<Result<T, E>> {
  /// Awaits a success transform, leaving an error payload unchanged.
  Future<Result<U, E>> map<U>(FutureOr<U> Function(T value) transform) => then((result) => result.mapAsync(transform));

  /// Awaits a result-returning operation on success, skipping it on error.
  Future<Result<U, E>> andThen<U>(FutureOr<Result<U, E>> Function(T value) transform) =>
      then((result) => result.andThenAsync(transform));

  /// Awaits an error transform, leaving a success payload unchanged.
  Future<Result<T, F>> mapError<F>(FutureOr<F> Function(E error) transform) =>
      then((result) => result.mapErrorAsync(transform));

  /// Awaits recovery of an error, leaving a success payload unchanged.
  Future<Result<T, E>> recover(FutureOr<Result<T, E>> Function(E error) onError) =>
      then((result) => result.recoverAsync(onError));
}
