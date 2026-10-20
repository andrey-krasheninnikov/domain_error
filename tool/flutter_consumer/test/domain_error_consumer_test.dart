import 'package:domain_error/domain_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('captures and transforms a synchronous success in Flutter', () {
    final result = captureResultSync(
      () => 21,
      options: CaptureResultSyncOptions(
        mapToDomainError: (error, stackTrace) => _ConsumerError(cause: error, stackTrace: stackTrace),
      ),
    );

    expect(result.map((value) => value * 2).fold((error) => -1, (value) => value), 42);
  });

  test('preserves an original domain error during asynchronous capture', () async {
    const original = _ConsumerError();
    final result = await captureResult<int>(
      () async => throw original,
      options: CaptureResultOptions(
        mapToDomainError: (error, stackTrace) => _ConsumerError(cause: error, stackTrace: stackTrace),
      ),
    );

    expect(result.domainError, same(original));
  });

  test('maps a raw error with diagnostic context in Flutter', () async {
    final cause = StateError('connection failed');
    final result = await captureResult<int>(
      () async => throw cause,
      options: CaptureResultOptions(
        mapToDomainError: (error, stackTrace) => _ConsumerError(cause: error, stackTrace: stackTrace),
      ),
    );

    expect(result.domainError.cause, same(cause));
    expect(result.domainError.stackTrace, isNotNull);
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
