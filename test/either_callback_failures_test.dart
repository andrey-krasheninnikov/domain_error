import 'dart:async';

import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  for (final method in ['map', 'andThen', 'mapError', 'recover']) {
    test('$method propagates the original exception and stack trace', () {
      final error = StateError('callback failed');
      final trace = StackTrace.fromString('callback trace');
      Never failCallback(Object? _) => Error.throwWithStackTrace(error, trace);
      try {
        const success = Either<Object?, Object?>.success(null);
        const failure = Either<Object?, Object?>.error(null);
        switch (method) {
          case 'map':
            success.map(failCallback);
          case 'andThen':
            success.andThen(failCallback);
          case 'mapError':
            failure.mapError(failCallback);
          case 'recover':
            failure.recover(failCallback);
        }
        fail('callback exception must propagate');
      } on Object catch (caught, caughtTrace) {
        expect(caught, same(error));
        expect(caughtTrace.toString(), trace.toString());
      }
    });

    for (final asynchronous in [false, true]) {
      test('${method}Async preserves a ${asynchronous ? 'delayed' : 'synchronous'} callback failure', () async {
        final error = StateError('callback failed');
        final trace = StackTrace.fromString('callback trace');
        final gate = Completer<Never>();
        FutureOr<Never> failCallback(Object? _) {
          if (asynchronous) return gate.future;
          Error.throwWithStackTrace(error, trace);
        }

        const success = Either<Object?, Object?>.success(null);
        const failure = Either<Object?, Object?>.error(null);
        final pending = switch (method) {
          'map' => success.mapAsync(failCallback),
          'andThen' => success.andThenAsync(failCallback),
          'mapError' => failure.mapErrorAsync(failCallback),
          _ => failure.recoverAsync(failCallback),
        };
        final checked = _expectFailure(pending, error, trace);
        if (asynchronous) gate.completeError(error, trace);
        await checked;
      });
    }

    test('Future $method propagates source failure without invoking callbacks', () async {
      final error = StateError('source future failed');
      final trace = StackTrace.fromString('source trace');
      final source = Future<Either<Object?, Object?>>.error(error, trace);
      Never skipped(Object? _) => throw StateError('must skip');
      final pending = switch (method) {
        'map' => source.map(skipped),
        'andThen' => source.andThen(skipped),
        'mapError' => source.mapError(skipped),
        _ => source.recover(skipped),
      };
      await _expectFailure(pending, error, trace);
    });
  }
}

Future<void> _expectFailure(Future<Object?> pending, Object error, StackTrace trace) async {
  try {
    await pending;
    fail('future must fail');
  } on Object catch (caught, caughtTrace) {
    expect(caught, same(error));
    expect(caughtTrace.toString(), trace.toString());
  }
}
