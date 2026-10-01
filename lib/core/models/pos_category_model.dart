class PosCategoryModel {
  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;
  final List<PosItemModel> items;

  const PosCategoryModel({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isActive,
    this.items = const [],
  });

  factory PosCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    return PosCategoryModel(
      id:           json['id'] as String,
      name:         json['name'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive:     json['isActive'] as bool? ?? true,
      items: rawItems != null
          ? rawItems.map((e) => PosItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class PosItemModel {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final int? stock;
  final int displayOrder;
  final bool isActive;

  const PosItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.stock,
    required this.displayOrder,
    required this.isActive,
  });

  String get displayPrice =>
      'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  factory PosItemModel.fromJson(Map<String, dynamic> json) {
    return PosItemModel(
      id:           json['id'] as String,
      categoryId:   json['categoryId'] as String? ?? '',
      name:         json['name'] as String,
      price:        (json['price'] as num).toDouble(),
      stock:        json['stock'] as int?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive:     json['isActive'] as bool? ?? true,
    );
  }
}
