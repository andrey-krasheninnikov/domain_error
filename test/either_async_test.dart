import 'dart:async';

import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  test('mapAsync awaits the transform and skips an error', () async {
    final gate = Completer<String>();
    final pending = const Either<String, int>.success(7).mapAsync((value) {
      expect(value, 7);
      return gate.future;
    });
    gate.complete('mapped');
    expect((await pending).successValue, 'mapped');
    expect(
        (await const Either<String, int>.error('missing').mapAsync<int>((value) => throw StateError('must skip')))
            .errorValue,
        'missing');
  });
  test('andThenAsync awaits a result and short-circuits errors', () async {
    final gate = Completer<Either<String, int>>();
    final pending = const Either<String, int>.success(7).andThenAsync((value) {
      expect(value, 7);
      return gate.future;
    });
    gate.complete(const Either.error('next failed'));
    expect((await pending).errorValue, 'next failed');
    expect(
        (await const Either<String, int>.error('missing').andThenAsync<int>((value) => throw StateError('must skip')))
            .errorValue,
        'missing');
  });
  test('mapErrorAsync awaits an error transform and preserves success', () async {
    final gate = Completer<int>();
    final pending = const Either<String, int>.error('missing').mapErrorAsync((error) {
      expect(error, 'missing');
      return gate.future;
    });
    gate.complete(404);
    expect((await pending).errorValue, 404);
    final value = Object();
    expect(
        (await Either<String, Object>.success(value).mapErrorAsync<int>((error) => throw StateError('must skip')))
            .successValue,
        same(value));
  });
  test('recoverAsync awaits a fallback and skips success', () async {
    final gate = Completer<Either<String, int>>();
    final pending = const Either<String, int>.error('missing').recoverAsync((error) {
      expect(error, 'missing');
      return gate.future;
    });
    gate.complete(const Either.success(42));
    expect((await pending).successValue, 42);
    expect(
        (await const Either<String, int>.success(7).recoverAsync((error) => throw StateError('must skip')))
            .successValue,
        7);
  });
  test('Future Either composes sequentially with inferred result types', () async {
    final start = Completer<Result<int>>();
    final gate = Completer<Result<String>>();
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
        .recover((error) => const Either.success(-1));
    expect(events, isEmpty);
    start.complete(const Either.success(7));
    await entered.future;
    expect(events, ['chain 7']);
    gate.complete(const Either.success('value'));
    final result = await pending;
    expect(result, isA<Result<int>>());
    expect(result.successValue, 5);
    expect(events, ['chain 7', 'map value']);
  });
  test('Future error steps await mapping and recovery in order', () async {
    final mapped = Completer<Object>();
    final recovered = Completer<Either<Object, int>>();
    final mappingStarted = Completer<void>();
    final recoveryStarted = Completer<void>();
    final original = Object();
    final replacement = Object();
    final events = <String>[];
    final pending = Future.value(Either<Object, int>.error(original))
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
    recovered.complete(const Either.success(42));
    expect((await pending).successValue, 42);
  });

  test('async nullable payloads and explicit type arguments remain valid', () async {
    const success = Either<String?, int?>.success(null);
    const error = Either<String?, int?>.error(null);
    final mapped = await success.mapAsync<String?>((value) async => null);
    expect(mapped.successValue, isNull);
    expect((await success.andThenAsync<int?>((value) async => Either.success(value))).successValue, isNull);
    expect((await error.mapErrorAsync<String?>((value) async => value)).errorValue, isNull);
    expect((await error.recoverAsync((value) async => const Either.success(null))).isSuccess, isTrue);
    expect((await error.recoverAsync(Either<String?, int?>.error)).isError, isTrue);
    final done = await success.mapAsync<void>((value) async {});
    expect(done.isSuccess, isTrue);
  });
}
