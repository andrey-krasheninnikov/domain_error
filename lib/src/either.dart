import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const DeepCollectionEquality _payloadEquality = DeepCollectionEquality();

/// A value that is either an [errorValue] or a [successValue].
///
/// Equality requires the same concrete type (including type arguments) and
/// deeply equal payloads. The payload is stored by reference without copying.
/// Keep it and any nested collections immutable, especially when using an
/// [Either] as a map key or set element.
@immutable
sealed class Either<L, R> {
  /// Whether this instance holds an error value.
  bool get isError => this is EitherError<L, R>;

  /// Whether this instance holds a success value.
  bool get isSuccess => this is EitherSuccess<L, R>;

  /// The error side of [Either].
  L get errorValue => switch (this) {
        EitherError(:final errorValue) => errorValue,
        EitherSuccess() => throw StateError('Either.success has no errorValue'),
      };

  /// The success side of [Either].
  R get successValue => switch (this) {
        EitherSuccess(:final successValue) => successValue,
        EitherError() => throw StateError('Either.error has no successValue'),
      };

  /// Creates an [Either].
  const Either();

  /// Creates an error [Either].
  const factory Either.error(L errorValue) = EitherError<L, R>;

  /// Creates a successful [Either].
  const factory Either.success(R successValue) = EitherSuccess<L, R>;

  /// Applies [onError] or [onSuccess] depending on the held value.
  T fold<T>(
    T Function(L errorValue) onError,
    T Function(R successValue) onSuccess,
  ) {
    return switch (this) {
      EitherError(:final errorValue) => onError(errorValue),
      EitherSuccess(:final successValue) => onSuccess(successValue),
    };
  }

  /// Maps the success value, leaving an error unchanged.
  Either<L, R2> map<R2>(R2 Function(R successValue) transform) {
    return switch (this) {
      EitherError(:final errorValue) => Either.error(errorValue),
      EitherSuccess(:final successValue) => Either.success(transform(successValue)),
    };
  }
}

/// [Either] that holds an error value.
@immutable
final class EitherError<L, R> extends Either<L, R> {
  @override
  final L errorValue;

  @override
  int get hashCode => Object.hash(runtimeType, _payloadEquality.hash(errorValue));

  /// Creates an error [Either].
  const EitherError(this.errorValue);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is EitherError<L, R> &&
        _payloadEquality.equals(errorValue, other.errorValue) &&
        _payloadEquality.equals(other.errorValue, errorValue);
  }
}

/// [Either] that holds a success value.
@immutable
final class EitherSuccess<L, R> extends Either<L, R> {
  @override
  final R successValue;

  @override
  int get hashCode => Object.hash(runtimeType, _payloadEquality.hash(successValue));

  /// Creates a successful [Either].
  const EitherSuccess(this.successValue);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is EitherSuccess<L, R> &&
        _payloadEquality.equals(successValue, other.successValue) &&
        _payloadEquality.equals(other.successValue, successValue);
  }
}
