import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  test('public result names put the success type first and expose branch fields', () {
    const success = Result<int, String>.success(7);
    const error = Result<int, String>.error('missing');
    expect(success.value, 7);
    expect(error.error, 'missing');
    expect(
        switch (success) {
          ResultSuccess(:final value) => value,
          ResultError(:final error) => error.length,
        },
        7);
    expect(success.fold((error) => error.length, (value) => value * 2), 14);
    expect(() => success.error,
        throwsA(isA<StateError>().having((error) => error.message, 'message', 'Either.success has no errorValue')));
    expect(() => error.value,
        throwsA(isA<StateError>().having((error) => error.message, 'message', 'Either.error has no successValue')));
  });

  test('domain aliases expose both constructors and the named error extension', () {
    const original = _SampleError();
    const success = DomainResult<int>.success(7);
    const error = DomainResult<int>.error(original);
    expect(success.value, 7);
    expect(DomainResultError<int>(error).domainError, same(original));
    expect(error.error, same(original));
  });

  test('the Future extension composes a FutureDomainResult with inferred types', () async {
    FutureDomainResult<int> capture() => captureResult(
          () async => 20,
          mapToDomainError: (error, trace) => const _SampleError(),
        );
    final result = await FutureResult<int, DomainError>(capture())
        .andThen((value) async => Result.success(value + 1))
        .map((value) => value * 2)
        .mapError((error) => error)
        .recover((error) => const Result.success(-1));
    expect(result, const Result<int, DomainError>.success(42));
  });
}

final class _SampleError extends DomainError {
  @override
  String get typeIdentifier => 'sample.error';

  const _SampleError();
}
