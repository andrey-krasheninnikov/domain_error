import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('value exposes payload and fold branch', () {
      const result = Result<int, DomainError>.success(7);

      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.value, 7);
      expect(result.fold((error) => 0, (value) => value), 7);
    });

    test('error exposes payload and fold branch', () {
      const error = _TestDomainError(message: 'missing');
      const result = Result<int, DomainError>.error(error);

      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.error, error);
      expect(result.fold((value) => value, (value) => value), error);
    });

    test('maps the success value and leaves an error unchanged', () {
      const ok = Result<int, DomainError>.success(7);
      const err = Result<int, DomainError>.error(_TestDomainError(message: 'missing'));

      expect(ok.map((value) => value * 2).value, 14);
      expect(err.map((value) => value * 2).error, err.error);
    });

    test('compares equal when held values match', () {
      const left = Result<String, DomainError>.success('ok');
      const right = Result<String, DomainError>.success('ok');

      expect(left, equals(right));
    });

    for (final errorBranch in [false, true]) {
      test('equality is symmetric with generic types, error branch: $errorBranch', () {
        final wide = errorBranch ? const Result<num, Object>.error('x') : const Result<num, Object>.success(1);
        final narrow = errorBranch ? const Result<int, String>.error('x') : const Result<int, String>.success(1);
        expect(wide == narrow, isFalse);
        expect(narrow == wide, isFalse);
        expect({wide, narrow}, hasLength(2));
      });

      test('deep equality and hashing, error branch: $errorBranch', () {
        final first = <String, Object?>{
          'list': [
            1,
            null,
            {
              'nested': [2, 3],
            },
          ],
          'set': {4, 5},
        };
        final second = <String, Object?>{
          'set': {5, 4},
          'list': [
            1,
            null,
            {
              'nested': [2, 3],
            },
          ],
        };
        final a = errorBranch ? Result<Object?, Object?>.error(first) : Result<Object?, Object?>.success(first);
        final b = errorBranch ? Result<Object?, Object?>.error(second) : Result<Object?, Object?>.success(second);
        expect(a == b, isTrue);
        expect(b == a, isTrue);
        expect(a.hashCode, b.hashCode);
        expect({a, b}, hasLength(1));
        expect({a}.contains(b), isTrue);
        final opposite = errorBranch ? Result<Object?, Object?>.success(first) : Result<Object?, Object?>.error(first);
        expect(a, isNot(equals(opposite)));
      });

      test('mixed collection kinds compare symmetrically, error branch: $errorBranch', () {
        final list = [1, 2];
        final iterable = list.map((value) => value);
        final a = errorBranch ? Result<Object, Object>.error(list) : Result<Object, Object>.success(list);
        final b = errorBranch ? Result<Object, Object>.error(iterable) : Result<Object, Object>.success(iterable);
        expect(a == b, isFalse);
        expect(b == a, isFalse);
      });
    }

    test('wrong branch getters throw StateError', () {
      const success = Result<int, String>.success(1);
      const error = Result<int, String>.error('missing');
      expect(() => success.error, throwsStateError);
      expect(() => error.value, throwsStateError);
    });

    test('nullable values keep their branch identity', () {
      const success = Result<int?, String?>.success(null);
      const error = Result<int?, String?>.error(null);
      expect(success.isSuccess, isTrue);
      expect(success.value, isNull);
      expect(error.isError, isTrue);
      expect(error.error, isNull);
      expect(success, isNot(equals(error)));
      expect(success.map((value) => value?.toString()).value, isNull);
    });

    test('error map never invokes the transform', () {
      const error = Result<int, String>.error('missing');
      final mapped = error.map<String>((value) => throw StateError('must not run'));
      expect(mapped.error, error.error);
    });

    test('unmodifiable snapshots preserve hashing after source collections change', () {
      final nested = [1, 2];
      final source = {'items': nested};
      final snapshot = Map<String, List<int>>.unmodifiable({
        for (final entry in source.entries) entry.key: List<int>.unmodifiable(entry.value),
      });
      final result = Result<Map<String, List<int>>, String>.success(snapshot);
      final hash = result.hashCode;
      final values = {result};
      nested.add(3);
      source.clear();
      expect(result.value, {
        'items': [1, 2],
      });
      expect(result.hashCode, hash);
      expect(values.contains(result), isTrue);
      expect(identical(result.value, snapshot), isTrue);
      expect(() => result.value.clear(), throwsUnsupportedError);
      expect(() => result.value['items']!.add(3), throwsUnsupportedError);
    });

    test('can hold an error that is not a DomainError', () {
      const result = Result<int, String>.error('missing');

      expect(result.isError, isTrue);
      expect(result.error, 'missing');
    });
  });
}

final class _TestDomainError extends DomainError {
  @override
  String get typeIdentifier => 'TestDomainError';

  const _TestDomainError({
    super.message,
  });
}
