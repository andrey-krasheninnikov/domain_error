// ignore_for_file: unreachable_from_main, avoid_print

import 'dart:async';

import 'package:domain_error/domain_error.dart';

/// Loads an order and prints `value` / `error` for typical outcomes.
Future<void> main() async {
  const logPrefix = 'main():';

  for (final id in ['42', '', 'timeout', 'boom']) {
    final result = await captureResult<Order>(
      () async {
        if (id.isEmpty) {
          throw const EmptyOrderIdError();
        }
        return loadOrder(id: id);
      },
      mapToDomainError: (rawError, stackTrace) {
        if (rawError is TimeoutException) {
          return const OrderTimeoutError();
        } else {
          return OrderUnavailableError(cause: rawError, stackTrace: stackTrace);
        }
      },
      onDomainError: (domainError, stackTrace) async {
        print('$logPrefix ${domainError.typeIdentifier} $stackTrace');
      },
      onRawError: (rawError, stackTrace) async {
        print('$logPrefix $rawError $stackTrace');
      },
      onObserverError: (observerError, stackTrace) {
        print('$logPrefix observer failed: $observerError $stackTrace');
      },
    );

    print(
      result.fold(
        (domainError) => '$logPrefix $domainError',
        (value) => '$logPrefix $value',
      ),
    );
  }

  final syncResult = captureResultSync<Order>(
    () => loadOrder(id: '42'),
    mapToDomainError: (rawError, stackTrace) {
      return OrderUnavailableError(cause: rawError, stackTrace: stackTrace);
    },
  );
  print(
    syncResult.fold(
      (domainError) => '$logPrefix sync $domainError',
      (value) => '$logPrefix sync $value',
    ),
  );
}

/// Reads an order or throws a domain [DomainError] / unexpected error.
Order loadOrder({required String id}) {
  if (id.trim().isEmpty) {
    throw const EmptyOrderIdError();
  }
  if (id == 'timeout') {
    throw TimeoutException('warehouse timeout');
  }
  if (id == 'boom') {
    throw StateError('warehouse timeout');
  }
  return Order(id: id, title: 'Notebook');
}

final class Order {
  final String id;
  final String title;

  const Order({
    required this.id,
    required this.title,
  });
}

sealed class OrderError extends DomainError {
  @override
  String get typeIdentifier => 'OrderError';

  const OrderError({
    super.message,
    super.cause,
    super.stackTrace,
  });
}

final class EmptyOrderIdError extends OrderError {
  @override
  String get typeIdentifier => 'OrderIdEmptyError';

  const EmptyOrderIdError();
}

final class OrderTimeoutError extends OrderError {
  @override
  String get typeIdentifier => 'OrderTimeoutError';

  const OrderTimeoutError();
}

final class OrderUnavailableError extends OrderError {
  @override
  String get typeIdentifier => 'OrderUnavailableError';

  const OrderUnavailableError({
    super.cause,
    super.stackTrace,
  });
}
