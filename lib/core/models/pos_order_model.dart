import 'pos_category_model.dart';

export 'pos_category_model.dart' show PosItemModel;

class CartItem {
  final PosItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get subtotal => item.price * quantity;

  String get displaySubtotal =>
      'Rp ${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

class PosOrderModel {
  final String id;
  final String? sessionId;
  final String kasirId;
  final double subtotal;
  final List<PosOrderItemModel> items;
  final DateTime createdAt;

  const PosOrderModel({
    required this.id,
    this.sessionId,
    required this.kasirId,
    required this.subtotal,
    required this.items,
    required this.createdAt,
  });

  factory PosOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    return PosOrderModel(
      id:        json['id'] as String,
      sessionId: json['sessionId'] as String?,
      kasirId:   json['kasirId'] as String,
      subtotal:  (json['subtotal'] as num).toDouble(),
      items: rawItems != null
          ? rawItems.map((e) => PosOrderItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PosOrderItemModel {
  final String id;
  final String orderId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const PosOrderItemModel({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory PosOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PosOrderItemModel(
      id:        json['id'] as String,
      orderId:   json['orderId'] as String,
      itemId:    json['itemId'] as String,
      itemName:  json['itemName'] as String,
      quantity:  json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal:  (json['subtotal'] as num).toDouble(),
    );
  }
}
