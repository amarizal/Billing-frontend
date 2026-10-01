class PackageModel {
  final String id;
  final String name;
  final String? description;
  final String type;  // 'package' | 'hourly'
  final int durationMinutes;
  final double price;
  final String? applicableTo; // 'PS4' | 'PS5' | null
  final int displayOrder;
  final bool isActive;

  const PackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.durationMinutes,
    required this.price,
    this.applicableTo,
    required this.displayOrder,
    required this.isActive,
  });

  bool get isHourly => type == 'hourly';

  String get displayDuration {
    if (isHourly) return 'Per Jam';
    if (durationMinutes < 60) return '$durationMinutes Menit';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m > 0 ? '$h Jam $m Menit' : '$h Jam';
  }

  String get displayPrice =>
      'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id:              json['id'] as String,
      name:            json['name'] as String,
      description:     json['description'] as String?,
      type:            json['type'] as String,
      durationMinutes: (json['durationMinutes'] ?? json['duration_minutes']) as int? ?? 0,
      price:           (json['price'] as num).toDouble(),
      applicableTo:    (json['applicableTo'] ?? json['applicable_to']) as String?,
      displayOrder:    (json['displayOrder'] ?? json['display_order']) as int? ?? 0,
      isActive:        (json['isActive'] ?? json['is_active']) as bool? ?? true,
    );
  }
}
