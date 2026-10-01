import 'session_model.dart';

class UnitModel {
  final String id;
  final String name;
  final String type;   // 'PS4' | 'PS5'
  final String status; // 'available' | 'in_use' | 'maintenance'
  final int displayOrder;
  final bool isActive;
  final String? ipAddress;
  final String? tuyaDeviceId;
  final SessionModel? activeSession; // session aktif saat ini (jika ada)

  const UnitModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.displayOrder,
    required this.isActive,
    this.ipAddress,
    this.tuyaDeviceId,
    this.activeSession,
  });

  bool get isAvailable   => status == 'available';
  bool get isInUse       => status == 'in_use';
  bool get isMaintenance => status == 'maintenance';
  bool get isPs5         => type == 'PS5';

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final sessions = json['sessions'] as List?;
    return UnitModel(
      id:           json['id'] as String? ?? '',
      name:         json['name'] as String? ?? '',
      type:         json['type'] as String? ?? '',
      status:       json['status'] as String? ?? 'available',
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive:     json['isActive'] ?? json['is_active'] as bool? ?? true,
      ipAddress:    json['ipAddress'] ?? json['ip_address'] as String?,
      tuyaDeviceId: json['tuyaDeviceId'] ?? json['tuya_device_id'] as String?,
      activeSession: (sessions != null && sessions.isNotEmpty)
          ? SessionModel.fromJson(sessions.first as Map<String, dynamic>)
          : null,
    );
  }
}
