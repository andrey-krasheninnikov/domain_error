/// Domain errors and helpers for handling them.
///
/// Start with `DomainError`, fold outcomes with `Result` or `DomainResult`, and
/// convert thrown errors through `captureResult` or `captureResultSync`.
library;

export 'src/capture_result.dart';
export 'src/domain_error.dart';
export 'src/domain_result.dart';
export 'src/result.dart';
