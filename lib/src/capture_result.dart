import 'dart:async';

import 'package:domain_error/src/domain_error.dart';
import 'package:domain_error/src/either.dart';
import 'package:domain_error/src/result.dart';

/// Runs [operation] and captures its outcome in a [Result].
///
/// A successful call becomes [Either.success]. A thrown [DomainError] becomes
/// [Either.error] with the same instance after [onDomainError].
/// Any other thrown object is observed by [onRawError],
/// then converted by [mapToDomainError]. The mapped error
/// does not trigger [onDomainError].
///
/// Awaits the operation, observers, observer error handler, and mapper in order.
/// Observer failures reach optional [onObserverError]; without it they are
/// ignored. Failures of that reporter are also ignored, without recursion.
/// Observation never replaces the result. Mapper failures propagate with their
/// original stack trace; they are not passed to an observer.
Future<Result<T>> captureResult<T>(
  FutureOr<T> Function() operation, {
  required FutureOr<DomainError> Function(Object rawError, StackTrace stackTrace) mapToDomainError,
  FutureOr<void> Function(DomainError domainError, StackTrace stackTrace)? onDomainError,
  FutureOr<void> Function(Object rawError, StackTrace stackTrace)? onRawError,
  FutureOr<void> Function(Object observerError, StackTrace stackTrace)? onObserverError,
}) async {
  try {
    return Either.success(await operation());
  } on Object catch (error, stackTrace) {
    if (error is DomainError) {
      await _observe(onDomainError, error, stackTrace, onObserverError);
      return Either.error(error);
    }

    await _observe(onRawError, error, stackTrace, onObserverError);
    final domainError = await mapToDomainError(error, stackTrace);
    return Either.error(domainError);
  }
}

/// Runs [operation] synchronously and captures its outcome in a [Result].
///
/// Uses the same error routing as [captureResult]. The mapper and observers
/// complete synchronously. Observers return `Null`, so async functions and
/// `void` tear-offs do not match their types. Wrap a synchronous `void` function
/// in a block returning null. This checks callback return types, not internal
/// work started without awaiting it.
///
/// Stores the returned [T] unchanged, including a `Future` payload. Such a
/// future is not awaited; its later failures remain the caller's responsibility.
/// Use [captureResult] to capture asynchronous completion instead.
///
/// Observer failures never replace the result. Mapper failures propagate with
/// their original stack trace.
Result<T> captureResultSync<T>(
  T Function() operation, {
  required DomainError Function(Object rawError, StackTrace stackTrace) mapToDomainError,
  Null Function(DomainError domainError, StackTrace stackTrace)? onDomainError,
  Null Function(Object rawError, StackTrace stackTrace)? onRawError,
  Null Function(Object observerError, StackTrace stackTrace)? onObserverError,
}) {
  try {
    return Either.success(operation());
  } on Object catch (error, stackTrace) {
    if (error is DomainError) {
      _observeSync(onDomainError, error, stackTrace, onObserverError);
      return Either.error(error);
    }

    _observeSync(onRawError, error, stackTrace, onObserverError);
    final domainError = mapToDomainError(error, stackTrace);
    return Either.error(domainError);
  }
}

Future<void> _observe<T>(
  FutureOr<void> Function(T error, StackTrace stackTrace)? observer,
  T error,
  StackTrace stackTrace,
  FutureOr<void> Function(Object observerError, StackTrace stackTrace)? onObserverError,
) async {
  if (observer == null) {
    return;
  }
  try {
    await observer(error, stackTrace);
  } on Object catch (observerError, observerStackTrace) {
    try {
      await onObserverError?.call(observerError, observerStackTrace);
    } on Object {
      // Reporting must never replace the operation's result or recurse.
    }
  }
}

void _observeSync<T>(
  Null Function(T error, StackTrace stackTrace)? observer,
  T error,
  StackTrace stackTrace,
  Null Function(Object observerError, StackTrace stackTrace)? onObserverError,
) {
  if (observer == null) {
    return;
  }
  try {
    observer(error, stackTrace);
  } on Object catch (observerError, observerStackTrace) {
    try {
      onObserverError?.call(observerError, observerStackTrace);
    } on Object {
      // Reporting must never replace the operation's result or recurse.
    }
  }
}
