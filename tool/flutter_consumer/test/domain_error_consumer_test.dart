import 'package:domain_error/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('captures and transforms a synchronous success in Flutter', () {
    final result = captureResultSync(
      () => 21,
      mapToDomainError: (error, stackTrace) => _ConsumerError(cause: error, stackTrace: stackTrace),
    );

    expect(result.map((value) => value * 2).fold((error) => -1, (value) => value), 42);
  });

  test('preserves an original domain error during asynchronous capture', () async {
    const original = _ConsumerError();
    final result = await captureResult<int>(
      () async => throw original,
      mapToDomainError: (error, stackTrace) => _ConsumerError(cause: error, stackTrace: stackTrace),
    );

    expect(result.domainError, same(original));
  });

  test('maps a raw error with diagnostic context in Flutter', () async {
    final cause = StateError('connection failed');
    final result = await captureResult<int>(
      () async => throw cause,
      mapToDomainError: (error, stackTrace) => _ConsumerError(cause: error, stackTrace: stackTrace),
    );

    expect(result.domainError.cause, same(cause));
    expect(result.domainError.stackTrace, isNotNull);
  });

  test('composes and recovers asynchronous results in Flutter', () async {
    const original = _ConsumerError();
    final result = await captureResult<int>(
      () async => 21,
      mapToDomainError: (error, trace) => _ConsumerError(cause: error, stackTrace: trace),
    )
        .andThen((value) async => const Either<DomainError, int>.error(original))
        .map<int>((value) => throw StateError('must skip'))
        .mapError((error) {
      expect(error, same(original));
      return error;
    }).recover((error) async => const Either.success(42));
    expect(result.successValue, 42);
  });

  test('sync observers wrap void functions and nullable values stay valid', () {
    Object? observed;
    void observe(Object error, StackTrace trace) {
      observed = error;
    }

    const original = _ConsumerError();
    final result = captureResultSync<int?>(
      () => throw original,
      mapToDomainError: (error, trace) => throw StateError('must skip'),
      onDomainError: (error, trace) {
        observe(error, trace);
        return null;
      },
    ).recover((error) => const Either.success(null));
    expect(observed, same(original));
    expect(result.isSuccess, isTrue);
    expect(result.successValue, isNull);
  });

  test('compares collection payloads deeply in Flutter', () {
    final payload = [1, 2];
    final first = Either<String, List<int>>.success(payload);
    const second = Either<String, List<int>>.success([1, 2]);

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}

class _ConsumerError extends DomainError {
  @override
  String get typeIdentifier => 'consumer.error';

  const _ConsumerError({super.cause, super.stackTrace});
}
