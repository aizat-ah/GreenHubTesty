enum OrderStatus { pending, confirmed, outForDelivery, completed, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.pending:
        return '🕐';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.outForDelivery:
        return '🚚';
      case OrderStatus.completed:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
}

/// Granular delivery milestones — this is what satisfies SRS UC019
/// ("Picked Up / En Route / Delivered") and gives the buyer something
/// real to look at on the tracking screen.
enum DeliveryStage { assigned, pickedUp, enRoute, delivered }

extension DeliveryStageExt on DeliveryStage {
  String get label {
    switch (this) {
      case DeliveryStage.assigned:
        return 'Driver Assigned';
      case DeliveryStage.pickedUp:
        return 'Picked Up';
      case DeliveryStage.enRoute:
        return 'On The Way';
      case DeliveryStage.delivered:
        return 'Delivered';
    }
  }

  String get description {
    switch (this) {
      case DeliveryStage.assigned:
        return 'A driver has been assigned to your order.';
      case DeliveryStage.pickedUp:
        return 'Your order has been picked up from the supplier.';
      case DeliveryStage.enRoute:
        return 'Your driver is on the way to you.';
      case DeliveryStage.delivered:
        return 'Your order has been delivered. Enjoy!';
    }
  }

  int get step => DeliveryStage.values.indexOf(this); // 0..3, for progress UI

  static DeliveryStage fromName(String? value) {
    return DeliveryStage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeliveryStage.assigned,
    );
  }
}

enum PaymentMethod { cashOnDelivery, cardStripe }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.cardStripe:
        return 'Card (coming soon)';
    }
  }

  bool get isAvailable => this == PaymentMethod.cashOnDelivery;

  static PaymentMethod fromName(String? value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cashOnDelivery,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;
  String get formattedSubtotal => 'RM ${subtotal.toStringAsFixed(2)}';

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unit': unit,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final String note;
  final DateTime createdAt;
  // Driver assignment
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehiclePlate;
  // NEW: granular tracking + payment
  final DeliveryStage? deliveryStage;
  final PaymentMethod paymentMethod;
  final bool isPaid;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.note,
    required this.createdAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverVehiclePlate,
    this.deliveryStage,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.isPaid = false,
  });

  String get formattedTotal => 'RM ${totalPrice.toStringAsFixed(2)}';

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  bool get hasDriver => driverId != null && driverId!.isNotEmpty;

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      note: map['note'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      driverVehiclePlate: map['driverVehiclePlate'],
      deliveryStage: map['deliveryStage'] != null
          ? DeliveryStageExt.fromName(map['deliveryStage'])
          : null,
      paymentMethod: PaymentMethodExt.fromName(map['paymentMethod']),
      isPaid: map['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((i) => i.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.name,
      'note': note,
      'createdAt': createdAt,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      if (driverVehiclePlate != null) 'driverVehiclePlate': driverVehiclePlate,
      if (deliveryStage != null) 'deliveryStage': deliveryStage!.name,
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverVehiclePlate,
    DeliveryStage? deliveryStage,
    PaymentMethod? paymentMethod,
    bool? isPaid,
  }) {
    return OrderModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      totalPrice: totalPrice,
      status: status ?? this.status,
      note: note,
      createdAt: createdAt,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverVehiclePlate: driverVehiclePlate ?? this.driverVehiclePlate,
      deliveryStage: deliveryStage ?? this.deliveryStage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    // Firestore Timestamp
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }

  static OrderStatus _parseStatus(String? value) {
    switch (value) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'outForDelivery':
        return OrderStatus.outForDelivery;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}