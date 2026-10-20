import 'dart:async';

import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  group('captureResult', () {
    test('awaits a delayed success without invoking observers or mapper', () async {
      final operation = Completer<int>();
      final observations = <String>[];
      final result = captureResult<int>(
        () => operation.future,
        options: CaptureResultOptions(
          mapToDomainError: (_, __) => throw StateError('unexpected mapper'),
          onDomainError: (_, __) => observations.add('domain'),
          onRawError: (_, __) => observations.add('raw'),
          onObserverError: (_, __) => observations.add('observer error'),
        ),
      );
      operation.complete(9);
      expect((await result).successValue, 9);
      expect(observations, isEmpty);
    });

    for (final domainCase in [false, true]) {
      test('captures a delayed error with its original trace, domain: $domainCase', () async {
        final original = domainCase ? const _TestDomainError() : StateError('operation failed');
        final trace = StackTrace.fromString('operation trace');
        final operation = Completer<int>();
        Object? observed;
        StackTrace? observedTrace;
        final result = captureResult<int>(
          () => operation.future,
          options: CaptureResultOptions(
            onDomainError: (error, stackTrace) {
              observed = error;
              observedTrace = stackTrace;
            },
            onRawError: (error, stackTrace) {
              observed = error;
              observedTrace = stackTrace;
            },
            mapToDomainError: (error, stackTrace) async {
              expect(domainCase, isFalse);
              return _TestDomainError(cause: error, stackTrace: stackTrace);
            },
          ),
        );
        operation.completeError(original, trace);
        final captured = await result;
        expect(observed, same(original));
        expect(observedTrace.toString(), trace.toString());
        if (domainCase) {
          expect(captured.domainError, same(original));
        } else {
          expect(captured.domainError.cause, same(original));
          expect(captured.domainError.stackTrace.toString(), trace.toString());
        }
      });

      for (final asynchronous in [false, true]) {
        for (final reporting in ['absent', 'success', 'failure']) {
          test('preserves result: domain=$domainCase, async=$asynchronous, reporter=$reporting', () async {
            final original = domainCase ? const _TestDomainError() : StateError('operation failed');
            final operationTrace = StackTrace.fromString('operation trace');
            final observerError = StateError('observer failed');
            final observerTrace = StackTrace.fromString('observer trace');
            var reported = 0;
            Object? reportedError;
            StackTrace? reportedTrace;
            final events = <String>[];

            FutureOr<void> observe(Object error, StackTrace stackTrace) {
              expect(error, same(original));
              expect(stackTrace.toString(), operationTrace.toString());
              events.add('observe');
              if (asynchronous) {
                return Future<void>.error(observerError, observerTrace);
              }
              Error.throwWithStackTrace(observerError, observerTrace);
            }

            FutureOr<void> report(Object error, StackTrace stackTrace) {
              reported++;
              events.add('report');
              reportedError = error;
              reportedTrace = stackTrace;
              if (reporting == 'failure') {
                if (asynchronous) {
                  return Future<void>.error(StateError('report failed'));
                }
                throw StateError('report failed');
              }
            }

            final result = await captureResult<int>(
              () => Error.throwWithStackTrace(original, operationTrace),
              options: CaptureResultOptions(
                onDomainError: domainCase ? observe : (_, __) => events.add('unexpected domain observer'),
                onRawError: domainCase ? (_, __) => events.add('unexpected raw observer') : observe,
                onObserverError: reporting == 'absent' ? null : report,
                mapToDomainError: (error, stackTrace) {
                  expect(domainCase, isFalse);
                  expect(error, same(original));
                  expect(stackTrace.toString(), operationTrace.toString());
                  events.add('map');
                  return _TestDomainError(cause: error, stackTrace: stackTrace);
                },
              ),
            );
            expect(result.isError, isTrue);
            expect(reported, reporting == 'absent' ? 0 : 1);
            if (reporting != 'absent') {
              expect(reportedError, same(observerError));
              expect(reportedTrace.toString(), observerTrace.toString());
            }
            expect(events, ['observe', if (reporting != 'absent') 'report', if (!domainCase) 'map']);
            expect(domainCase ? result.domainError : result.domainError.cause, same(original));
          });
        }
      }
    }

    test('awaits observer, reporter, and mapper in order', () async {
      final observerStarted = Completer<void>();
      final observerGate = Completer<void>();
      final reporterStarted = Completer<void>();
      final reporterGate = Completer<void>();
      final mapperStarted = Completer<void>();
      final mapperGate = Completer<DomainError>();
      final events = <String>[];
      final pending = captureResult<int>(
        () => throw StateError('operation failed'),
        options: CaptureResultOptions(
          onRawError: (_, __) async {
            events.add('observe');
            observerStarted.complete();
            await observerGate.future;
            throw StateError('observer failed');
          },
          onObserverError: (_, __) async {
            events.add('report');
            reporterStarted.complete();
            await reporterGate.future;
          },
          mapToDomainError: (_, __) {
            events.add('map');
            mapperStarted.complete();
            return mapperGate.future;
          },
        ),
      );
      await observerStarted.future;
      expect(events, ['observe']);
      observerGate.complete();
      await reporterStarted.future;
      expect(events, ['observe', 'report']);
      reporterGate.complete();
      await mapperStarted.future;
      expect(events, ['observe', 'report', 'map']);
      const mapped = _TestDomainError();
      mapperGate.complete(mapped);
      expect((await pending).domainError, same(mapped));
    });

    test('awaits a successful domain observer before returning the original error', () async {
      final started = Completer<void>();
      final gate = Completer<void>();
      var finished = false;
      const original = _TestDomainError();
      final pending = captureResult<int>(
        () => throw original,
        options: CaptureResultOptions(
          mapToDomainError: (_, __) => throw StateError('unexpected mapper'),
          onDomainError: (_, __) async {
            started.complete();
            await gate.future;
            finished = true;
          },
        ),
      );
      await started.future;
      expect(finished, isFalse);
      gate.complete();
      expect((await pending).domainError, same(original));
      expect(finished, isTrue);
    });

    for (final asynchronous in [false, true]) {
      test('mapper failures propagate unchanged, async: $asynchronous', () async {
        final mapperError = StateError('mapper failed');
        final mapperTrace = StackTrace.fromString('mapper trace');
        var reported = false;
        final pending = captureResult<int>(
          () => throw StateError('operation failed'),
          options: CaptureResultOptions(
            mapToDomainError: (_, __) {
              if (asynchronous) {
                return Future<DomainError>.error(mapperError, mapperTrace);
              }
              Error.throwWithStackTrace(mapperError, mapperTrace);
            },
            onObserverError: (_, __) {
              reported = true;
            },
          ),
        );
        try {
          await pending;
          fail('mapper failure must propagate');
        } on Object catch (error, stackTrace) {
          expect(error, same(mapperError));
          expect(stackTrace.toString(), mapperTrace.toString());
          expect(reported, isFalse);
        }
      });
    }

    test('returns the successful value', () async {
      final result = await captureResult<int>(
        () => 7,
        options: CaptureResultOptions(
          mapToDomainError: (rawError, stackTrace) => _TestDomainError(cause: rawError),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.successValue, 7);
    });

    test('returns thrown DomainError', () async {
      const error = _TestDomainError(message: 'handled error');
      DomainError? observedDomainError;

      final result = await captureResult<void>(
        () => throw error,
        options: CaptureResultOptions(
          mapToDomainError: (rawError, stackTrace) => _TestDomainError(cause: rawError),
          onDomainError: (domainError, stackTrace) {
            observedDomainError = domainError;
          },
        ),
      );

      expect(result.isError, isTrue);
      expect(result.domainError, error);
      expect(observedDomainError, error);
    });

    test('maps unexpected throw to DomainError', () async {
      Object? observedRawError;

      final result = await captureResult<void>(
        () => throw StateError('boom'),
        options: CaptureResultOptions(
          mapToDomainError: (rawError, stackTrace) => _TestDomainError(
            message: 'mapped error',
            cause: rawError,
            stackTrace: stackTrace,
          ),
          onRawError: (rawError, stackTrace) {
            observedRawError = rawError;
          },
        ),
      );

      expect(result.isError, isTrue);
      expect(result.domainError.typeIdentifier, 'TestDomainError');
      expect(result.domainError.message, 'mapped error');
      expect(observedRawError, isA<StateError>());
    });
  });

  group('captureResultSync', () {
    for (final domainCase in [false, true]) {
      for (final reporting in ['absent', 'success', 'failure']) {
        test('preserves result synchronously: domain=$domainCase, reporter=$reporting', () {
          final original = domainCase ? const _TestDomainError() : StateError('operation failed');
          final trace = StackTrace.fromString('operation trace');
          final observerError = StateError('observer failed');
          final observerTrace = StackTrace.fromString('observer trace');
          final events = <String>[];
          var reported = 0;
          Object? reportedError;
          StackTrace? reportedTrace;

          void observe(Object error, StackTrace stackTrace) {
            expect(error, same(original));
            expect(stackTrace.toString(), trace.toString());
            events.add('observe');
            Error.throwWithStackTrace(observerError, observerTrace);
          }

          void report(Object error, StackTrace stackTrace) {
            reported++;
            events.add('report');
            reportedError = error;
            reportedTrace = stackTrace;
            if (reporting == 'failure') {
              throw StateError('report failed');
            }
          }

          final result = captureResultSync<int>(
            () => Error.throwWithStackTrace(original, trace),
            options: CaptureResultSyncOptions(
              onDomainError: domainCase ? observe : (_, __) => events.add('unexpected domain observer'),
              onRawError: domainCase ? (_, __) => events.add('unexpected raw observer') : observe,
              onObserverError: reporting == 'absent' ? null : report,
              mapToDomainError: (error, stackTrace) {
                expect(domainCase, isFalse);
                expect(error, same(original));
                expect(stackTrace.toString(), trace.toString());
                events.add('map');
                return _TestDomainError(cause: error, stackTrace: stackTrace);
              },
            ),
          );
          expect(reported, reporting == 'absent' ? 0 : 1);
          if (reporting != 'absent') {
            expect(reportedError, same(observerError));
            expect(reportedTrace.toString(), observerTrace.toString());
          }
          expect(events, ['observe', if (reporting != 'absent') 'report', if (!domainCase) 'map']);
          expect(domainCase ? result.domainError : result.domainError.cause, same(original));
        });
      }
    }

    test('mapper failures propagate with their stack trace', () {
      final mapperError = StateError('mapper failed');
      final mapperTrace = StackTrace.fromString('mapper trace');
      var reported = false;
      try {
        captureResultSync<int>(
          () => throw StateError('operation failed'),
          options: CaptureResultSyncOptions(
            mapToDomainError: (_, __) => Error.throwWithStackTrace(mapperError, mapperTrace),
            onObserverError: (_, __) {
              reported = true;
            },
          ),
        );
        fail('mapper failure must propagate');
      } on Object catch (error, stackTrace) {
        expect(error, same(mapperError));
        expect(stackTrace.toString(), mapperTrace.toString());
        expect(reported, isFalse);
      }
    });

    test('unsupported async observer is not awaited by the sync API', () async {
      final gate = Completer<void>();
      final finished = Completer<void>();
      var observed = false;
      const original = _TestDomainError();
      final result = captureResultSync<int>(
        () => throw original,
        options: CaptureResultSyncOptions(
          mapToDomainError: (_, __) => throw StateError('unexpected mapper'),
          onDomainError: (_, __) async {
            await gate.future;
            observed = true;
            finished.complete();
          },
        ),
      );
      expect(result.domainError, same(original));
      expect(observed, isFalse);
      gate.complete();
      await finished.future;
      expect(observed, isTrue);
    });

    test('returns the successful value', () {
      final result = captureResultSync<int>(
        () => 7,
        options: CaptureResultSyncOptions(
          mapToDomainError: (rawError, stackTrace) => _TestDomainError(cause: rawError),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.successValue, 7);
    });

    test('returns thrown DomainError', () {
      const error = _TestDomainError(message: 'handled error');
      DomainError? observedDomainError;

      final result = captureResultSync<void>(
        () => throw error,
        options: CaptureResultSyncOptions(
          mapToDomainError: (rawError, stackTrace) => _TestDomainError(cause: rawError),
          onDomainError: (domainError, stackTrace) {
            observedDomainError = domainError;
          },
        ),
      );

      expect(result.isError, isTrue);
      expect(result.domainError, error);
      expect(observedDomainError, error);
    });

    test('maps unexpected throw to DomainError', () {
      Object? observedRawError;

      final result = captureResultSync<void>(
        () => throw StateError('boom'),
        options: CaptureResultSyncOptions(
          mapToDomainError: (rawError, stackTrace) => _TestDomainError(
            message: 'mapped error',
            cause: rawError,
            stackTrace: stackTrace,
          ),
          onRawError: (rawError, stackTrace) {
            observedRawError = rawError;
          },
        ),
      );

      expect(result.isError, isTrue);
      expect(result.domainError.typeIdentifier, 'TestDomainError');
      expect(result.domainError.message, 'mapped error');
      expect(observedRawError, isA<StateError>());
    });
  });
}

final class _TestDomainError extends DomainError {
  @override
  String get typeIdentifier => 'TestDomainError';

  const _TestDomainError({
    super.message,
    super.cause,
    super.stackTrace,
  });
}
