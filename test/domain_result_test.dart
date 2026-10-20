import 'package:domain_error/domain_error.dart';
import 'package:test/test.dart';

void main() {
  group('DomainResult', () {
    test('domainError throws for a successful DomainResult', () {
      const result = Result<int, DomainError>.success(7);
      expect(() => result.domainError, throwsStateError);
    });

    test('domainError reads the DomainError from a failed DomainResult', () {
      const error = _TestDomainError(message: 'missing');
      const result = Result<int, DomainError>.error(error);

      expect(result.domainError, error);
      expect(result.domainError, result.error);
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
