import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  test('andThen chains once in order and short-circuits errors', () {
    final events = <int>[];
    final error = Object();
    final result = const Result<int, Object>.success(2).andThen((value) {
      events.add(value);
      return Result.success(value + 3);
    }).andThen<String>((value) {
      events.add(value);
      return Result.error(error);
    }).andThen<int>((value) => throw StateError('must skip'));
    expect(events, [2, 5]);
    expect(result.error, same(error));
  });
  test('mapError changes the error type and preserves success identity', () {
    final value = Object();
    final success = Result<Object, String>.success(value).mapError<int>((error) => throw StateError('must skip'));
    expect(success.value, same(value));
    expect(const Result<int, String>.error('missing').mapError((error) => error.length).error, 7);
  });
  test('recover selects a fallback and can keep or replace an error', () {
    final value = Object();
    final success = Result<Object, String>.success(value);
    expect(success.recover((error) => throw StateError('must skip')).value, same(value));
    const missing = Result<int, String>.error('missing');
    expect(missing.recover((error) => error == 'missing' ? const Result.success(42) : Result.error(error)).value, 42);
    expect(missing.recover(Result<int, String>.error).error, 'missing');
    expect(missing.recover((error) => const Result.error('replacement')).error, 'replacement');
  });
  test('nullable payloads keep their branch through composition', () {
    const success = Result<int?, String?>.success(null);
    const error = Result<int?, String?>.error(null);
    expect(success.andThen(Result<int?, String?>.success).value, isNull);
    expect(error.andThen<int>((value) => throw StateError('must skip')).error, isNull);
    expect(success.mapError((value) => throw StateError('must skip')).value, isNull);
    expect(error.mapError((value) => value).error, isNull);
    expect(error.recover(Result<int?, String?>.error).isError, isTrue);
    expect(error.recover((value) => const Result.success(null)).isSuccess, isTrue);
    final done = success.map<void>((value) {});
    expect(done.andThen((value) => const Result.success(42)).value, 42);
  });
}
