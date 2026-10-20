import 'package:domain_error/domain_error.dart';

Future<void> main() async {
  final observed = <Object>[];
  void logError(Object error, StackTrace trace) => observed.add(error);

  const original = SampleError();
  final recovered = captureResultSync<int?>(
    () => throw original,
    mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
    onDomainError: (error, trace) {
      logError(error, trace);
      return null;
    },
  ).recover((error) => identical(error, original) ? const Result.success(null) : Result.error(error));
  assert(recovered.isSuccess && recovered.value == null);
  assert(identical(observed.single, original));

  final result = await compose();
  assert(result.value == 42);

  final translated = const Result<int, String>.error('missing').mapError((error) => error.length);
  assert(translated.error == 7);

  final asyncResult = await const Result<int, String>.success(21).andThenAsync((value) async {
    return Result.success(value * 2);
  });
  assert(asyncResult.value == 42);
}

FutureDomainResult<int> compose() => captureResult(
      () async => 20,
      mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
      onRawError: (error, trace) async {},
    )
        .andThen((value) async => Result.success(value + 1))
        .map((value) => value * 2)
        .mapError((error) => error)
        .recover((error) => const Result.success(-1));

class SampleError extends DomainError {
  @override
  String get typeIdentifier => 'sample.error';

  const SampleError({super.cause, super.stackTrace});
}
