import 'dart:async';

import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  test('mapAsync awaits the transform and skips an error', () async {
    final gate = Completer<String>();
    final pending = const Result<int, String>.success(7).mapAsync((value) {
      expect(value, 7);
      return gate.future;
    });
    gate.complete('mapped');
    expect((await pending).value, 'mapped');
    expect(
        (await const Result<int, String>.error('missing').mapAsync<int>((value) => throw StateError('must skip')))
            .error,
        'missing');
  });
  test('andThenAsync awaits a result and short-circuits errors', () async {
    final gate = Completer<Result<int, String>>();
    final pending = const Result<int, String>.success(7).andThenAsync((value) {
      expect(value, 7);
      return gate.future;
    });
    gate.complete(const Result.error('next failed'));
    expect((await pending).error, 'next failed');
    expect(
        (await const Result<int, String>.error('missing').andThenAsync<int>((value) => throw StateError('must skip')))
            .error,
        'missing');
  });
  test('mapErrorAsync awaits an error transform and preserves success', () async {
    final gate = Completer<int>();
    final pending = const Result<int, String>.error('missing').mapErrorAsync((error) {
      expect(error, 'missing');
      return gate.future;
    });
    gate.complete(404);
    expect((await pending).error, 404);
    final value = Object();
    expect(
        (await Result<Object, String>.success(value).mapErrorAsync<int>((error) => throw StateError('must skip')))
            .value,
        same(value));
  });
  test('recoverAsync awaits a fallback and skips success', () async {
    final gate = Completer<Result<int, String>>();
    final pending = const Result<int, String>.error('missing').recoverAsync((error) {
      expect(error, 'missing');
      return gate.future;
    });
    gate.complete(const Result.success(42));
    expect((await pending).value, 42);
    expect(
        (await const Result<int, String>.success(7).recoverAsync((error) => throw StateError('must skip'))).value, 7);
  });
  test('Future Result composes sequentially with inferred result types', () async {
    final start = Completer<DomainResult<int>>();
    final gate = Completer<DomainResult<String>>();
    final entered = Completer<void>();
    final events = <String>[];
    final pending = start.future
        .andThen((value) {
          events.add('chain $value');
          entered.complete();
          return gate.future;
        })
        .map((value) {
          events.add('map $value');
          return value.length;
        })
        .mapError((error) => error)
        .recover((error) => const Result.success(-1));
    expect(events, isEmpty);
    start.complete(const Result.success(7));
    await entered.future;
    expect(events, ['chain 7']);
    gate.complete(const Result.success('value'));
    final result = await pending;
    expect(result, isA<DomainResult<int>>());
    expect(result.value, 5);
    expect(events, ['chain 7', 'map value']);
  });
  test('Future error steps await mapping and recovery in order', () async {
    final mapped = Completer<Object>();
    final recovered = Completer<Result<int, Object>>();
    final mappingStarted = Completer<void>();
    final recoveryStarted = Completer<void>();
    final original = Object();
    final replacement = Object();
    final events = <String>[];
    final pending = Future.value(Result<int, Object>.error(original))
        .map<int>((value) => throw StateError('must skip'))
        .andThen<int>((value) => throw StateError('must skip'))
        .mapError((error) {
      expect(error, same(original));
      events.add('map error');
      mappingStarted.complete();
      return mapped.future;
    }).recover((error) {
      expect(error, same(replacement));
      events.add('recover');
      recoveryStarted.complete();
      return recovered.future;
    });
    await mappingStarted.future;
    expect(events, ['map error']);
    mapped.complete(replacement);
    await recoveryStarted.future;
    expect(events, ['map error', 'recover']);
    recovered.complete(const Result.success(42));
    expect((await pending).value, 42);
  });

  test('async nullable payloads and explicit type arguments remain valid', () async {
    const success = Result<int?, String?>.success(null);
    const error = Result<int?, String?>.error(null);
    final mapped = await success.mapAsync<String?>((value) async => null);
    expect(mapped.value, isNull);
    expect((await success.andThenAsync<int?>((value) async => Result.success(value))).value, isNull);
    expect((await error.mapErrorAsync<String?>((value) async => value)).error, isNull);
    expect((await error.recoverAsync((value) async => const Result.success(null))).isSuccess, isTrue);
    expect((await error.recoverAsync(Result<int?, String?>.error)).isError, isTrue);
    final done = await success.mapAsync<void>((value) async {});
    expect(done.isSuccess, isTrue);
  });
}
