// ─── Cart Item ───────────────────────────────────────────────────────────────
class CartItem {
  final int?   id;
  final int    productId;
  final String productName;
  final double price;
  final int    quantity;

  const CartItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'id': id, 'productId': productId, 'productName': productName,
    'price': price, 'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    id: m['id'], productId: m['productId'], productName: m['productName'],
    price: m['price'], quantity: m['quantity'],
  );

  CartItem copyWith({int? quantity}) => CartItem(
    id: id, productId: productId, productName: productName,
    price: price, quantity: quantity ?? this.quantity,
  );
}

// ─── Saved Card ───────────────────────────────────────────────────────────────
class SavedCard {
  final int?   id;
  final String cardHolder;
  final String maskedNumber;   // últimos 4 dígitos
  final String expiry;
  final String cardType;       // Mastercard / Visa
  final bool   isDefault;

  const SavedCard({
    this.id,
    required this.cardHolder,
    required this.maskedNumber,
    required this.expiry,
    required this.cardType,
    this.isDefault = false,
  });

  String get displayNumber => '**** **** **** $maskedNumber';

  Map<String, dynamic> toMap() => {
    'id': id, 'cardHolder': cardHolder, 'maskedNumber': maskedNumber,
    'expiry': expiry, 'cardType': cardType, 'isDefault': isDefault ? 1 : 0,
  };

  factory SavedCard.fromMap(Map<String, dynamic> m) => SavedCard(
    id: m['id'], cardHolder: m['cardHolder'], maskedNumber: m['maskedNumber'],
    expiry: m['expiry'], cardType: m['cardType'], isDefault: m['isDefault'] == 1,
  );
}

// ─── Order Item ───────────────────────────────────────────────────────────────
class OrderItem {
  final int?   id;
  final int    orderId;
  final int    productId;
  final String productName;
  final double unitPrice;
  final int    quantity;

  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
    'id': id, 'orderId': orderId, 'productId': productId,
    'productName': productName, 'unitPrice': unitPrice, 'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'], orderId: m['orderId'], productId: m['productId'],
    productName: m['productName'], unitPrice: m['unitPrice'], quantity: m['quantity'],
  );
}

// ─── Order ────────────────────────────────────────────────────────────────────
class Order {
  final int?       id;
  final String     orderCode;
  final double     totalAmount;
  final String     paymentMethod;
  final String     status;       // pending | completed | cancelled
  final String?    promoCode;
  final double     discount;
  final DateTime   createdAt;
  List<OrderItem>  items;

  Order({
    this.id,
    required this.orderCode,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.promoCode,
    this.discount = 0.0,
    required this.createdAt,
    this.items = const [],
  });

  double get finalAmount => totalAmount - discount;

  Map<String, dynamic> toMap() => {
    'id': id, 'orderCode': orderCode, 'totalAmount': totalAmount,
    'paymentMethod': paymentMethod, 'status': status,
    'promoCode': promoCode, 'discount': discount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    id: m['id'], orderCode: m['orderCode'], totalAmount: m['totalAmount'],
    paymentMethod: m['paymentMethod'], status: m['status'],
    promoCode: m['promoCode'], discount: m['discount'] ?? 0.0,
    createdAt: DateTime.parse(m['createdAt']),
  );

  Order copyWithId(int newId) => Order(
    id: newId, orderCode: orderCode, totalAmount: totalAmount,
    paymentMethod: paymentMethod, status: status, promoCode: promoCode,
    discount: discount, createdAt: createdAt, items: items,
  );
}