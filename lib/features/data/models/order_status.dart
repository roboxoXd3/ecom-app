enum OrderStatus {
  pending('pending'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  completed('completed'),
  cancelled('cancelled'),
  failed('failed'),
  returned('returned');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order has been placed and is awaiting confirmation';
      case OrderStatus.processing:
        return 'Your order is being prepared for shipment';
      case OrderStatus.shipped:
        return 'Your order has been shipped and is on its way';
      case OrderStatus.delivered:
        return 'Your order has been delivered successfully';
      case OrderStatus.completed:
        return 'Your order is complete';
      case OrderStatus.cancelled:
        return 'Your order has been cancelled';
      case OrderStatus.failed:
        return 'There was an issue processing your order';
      case OrderStatus.returned:
        return 'Your order has been returned';
    }
  }

  // Status color for UI
  String get colorHex {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA500'; // Orange
      case OrderStatus.processing:
        return '#2196F3'; // Blue
      case OrderStatus.shipped:
        return '#FF9800'; // Amber
      case OrderStatus.delivered:
        return '#4CAF50'; // Green
      case OrderStatus.completed:
        return '#4CAF50'; // Green
      case OrderStatus.cancelled:
        return '#F44336'; // Red
      case OrderStatus.failed:
        return '#F44336'; // Red
      case OrderStatus.returned:
        return '#9E9E9E'; // Grey
    }
  }

  // Status icon for UI
  String get iconName {
    switch (this) {
      case OrderStatus.pending:
        return 'schedule';
      case OrderStatus.processing:
        return 'settings';
      case OrderStatus.shipped:
        return 'local_shipping';
      case OrderStatus.delivered:
        return 'check_circle';
      case OrderStatus.completed:
        return 'done_all';
      case OrderStatus.cancelled:
        return 'cancel';
      case OrderStatus.failed:
        return 'error';
      case OrderStatus.returned:
        return 'keyboard_return';
    }
  }

  // Check if status can be cancelled
  bool get canBeCancelled {
    return this == OrderStatus.pending || this == OrderStatus.processing;
  }

  // Check if status is final (no more changes expected)
  bool get isFinal {
    return this == OrderStatus.completed ||
        this == OrderStatus.cancelled ||
        this == OrderStatus.failed ||
        this == OrderStatus.returned;
  }

  // Check if status indicates success
  bool get isSuccessful {
    return this == OrderStatus.delivered || this == OrderStatus.completed;
  }
}
