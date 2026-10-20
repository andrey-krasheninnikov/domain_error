import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  test('andThen chains once in order and short-circuits errors', () {
    final events = <int>[];
    final error = Object();
    final result = const Either<Object, int>.success(2).andThen((value) {
      events.add(value);
      return Either.success(value + 3);
    }).andThen<String>((value) {
      events.add(value);
      return Either.error(error);
    }).andThen<int>((value) => throw StateError('must skip'));
    expect(events, [2, 5]);
    expect(result.errorValue, same(error));
  });
  test('mapError changes the error type and preserves success identity', () {
    final value = Object();
    final success = Either<String, Object>.success(value).mapError<int>((error) => throw StateError('must skip'));
    expect(success.successValue, same(value));
    expect(const Either<String, int>.error('missing').mapError((error) => error.length).errorValue, 7);
  });
  test('recover selects a fallback and can keep or replace an error', () {
    final value = Object();
    final success = Either<String, Object>.success(value);
    expect(success.recover((error) => throw StateError('must skip')).successValue, same(value));
    const missing = Either<String, int>.error('missing');
    expect(missing.recover((error) => error == 'missing' ? const Either.success(42) : Either.error(error)).successValue,
        42);
    expect(missing.recover(Either<String, int>.error).errorValue, 'missing');
    expect(missing.recover((error) => const Either.error('replacement')).errorValue, 'replacement');
  });
  test('nullable payloads keep their branch through composition', () {
    const success = Either<String?, int?>.success(null);
    const error = Either<String?, int?>.error(null);
    expect(success.andThen(Either<String?, int?>.success).successValue, isNull);
    expect(error.andThen<int>((value) => throw StateError('must skip')).errorValue, isNull);
    expect(success.mapError((value) => throw StateError('must skip')).successValue, isNull);
    expect(error.mapError((value) => value).errorValue, isNull);
    expect(error.recover(Either<String?, int?>.error).isError, isTrue);
    expect(error.recover((value) => const Either.success(null)).isSuccess, isTrue);
    final done = success.map<void>((value) {});
    expect(done.andThen((value) => const Either.success(42)).successValue, 42);
  });
}
