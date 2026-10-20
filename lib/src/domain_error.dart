import 'package:equatable/equatable.dart';

/// Expected domain or application error.
///
/// Feature error roots extend [DomainError] in their own libraries. Keep this
/// type as an `abstract class` so those roots can live outside this file.
/// [typeIdentifier] remains readable after obfuscation.
///
/// Equality includes the concrete type, [typeIdentifier], and [message].
/// [cause] and [stackTrace] are diagnostic context and do not affect equality.
/// Add business fields in subclasses with `[...super.props, field]`.
abstract class DomainError extends Equatable implements Exception {
  /// Stable identifier used in logs and error reporting.
  ///
  /// Keep its value unchanged even when renaming the Dart class.
  String get typeIdentifier;

  /// Optional human-readable description.
  final String? message;

  /// Optional technical cause, including a nested [DomainError].
  final Object? cause;

  /// Optional stack trace of the technical cause.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [typeIdentifier, message];

  String? get _displayDetail {
    final description = _firstLine(message ?? '');
    if (description.isNotEmpty) {
      return description;
    }

    final cause = this.cause;
    if (cause == null) {
      return null;
    }

    try {
      if (cause is DomainError) {
        return cause.typeIdentifier;
      }
      final detail = _firstLine(cause.toString());
      if (detail.isEmpty || detail.startsWith('Instance of ')) {
        return 'unknown';
      }
      return detail;
    } on Object {
      return 'unknown';
    }
  }

  /// Creates a [DomainError].
  const DomainError({this.message, this.cause, this.stackTrace});

  @override
  String toString() {
    final detail = _displayDetail;
    if (detail == null || detail.isEmpty) {
      return typeIdentifier;
    }
    return '$typeIdentifier($detail)';
  }
}

String _firstLine(String value) => value.trim().split(RegExp(r'\r\n?|\n')).first.trim();
