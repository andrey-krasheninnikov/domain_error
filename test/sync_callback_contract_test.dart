import 'dart:io';

import 'package:test/test.dart';

void main() {
  for (final parameter in ['onDomainError', 'onRawError', 'onObserverError']) {
    for (final callback in {
      'wrapped void function': '(error, trace) { logError(error, trace); return null; }',
      'async closure': '(error, trace) async {}',
      'async tear-off': 'logAsyncError',
      'void tear-off': 'logError',
    }.entries) {
      test('$parameter accepts only a synchronous Null callback: ${callback.key}', () async {
        final directory = await Directory.systemTemp.createTemp('sync-callback-contract-');
        addTearDown(() => directory.delete(recursive: true));
        final program = File('${directory.path}/consumer.dart');
        await program.writeAsString('''
import 'package:domain_error/domain_error.dart';
void logError(Object error, StackTrace trace) {}
Future<void> logAsyncError(Object error, StackTrace trace) async {}
class SampleError extends DomainError {
  String get typeIdentifier => 'sample.error';
}
void main() {
  final DomainResult<int> result = captureResultSync(
    () => 42,
    mapToDomainError: (error, trace) => SampleError(),
    $parameter: ${callback.value},
  );
  if (result.value != 42) throw StateError('wrong result');
}
''');
        final compiled = await Process.run(Platform.resolvedExecutable, [
          '--disable-dart-dev',
          '--packages=${File('.dart_tool/package_config.json').absolute.path}',
          program.path,
        ]);
        if (callback.key == 'wrapped void function') {
          expect(compiled.exitCode, 0, reason: '${compiled.stderr}');
        } else {
          expect(compiled.exitCode, isNot(0));
          expect(compiled.stderr, contains('Null Function('));
          expect(compiled.stderr, isNot(contains("Couldn't resolve the package")));
        }
      });
    }
  }
}
