import '../constants/app_constants.dart';
import 'package_model.dart';
import 'user_model.dart';
import 'unit_model.dart';

class SessionModel {
  final String id;
  final String unitId;
  final String kasirId;
  final String? packageId;
  final DateTime startTime;
  final DateTime? plannedEndTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? billingAmount;
  final double? posAmount;
  final String? extendedInfo;
  final String status; // 'active' | 'completed' | 'cancelled'
  final String? notes;
  final DateTime createdAt;

  // Embedded relations (opsional)
  final PackageModel? package;
  final UserModel? kasir;
  final UnitModel? unit;

  const SessionModel({
    required this.id,
    required this.unitId,
    required this.kasirId,
    this.packageId,
    required this.startTime,
    this.plannedEndTime,
    this.endTime,
    this.durationMinutes,
    this.billingAmount,
    this.posAmount,
    this.extendedInfo,
    required this.status,
    this.notes,
    required this.createdAt,
    this.package,
    this.kasir,
    this.unit,
  });

  bool get isActive    => status == 'active';
  bool get isCompleted => status == 'completed';

  /// Durasi berjalan saat ini (untuk timer real-time)
  Duration get elapsed => DateTime.now().difference(startTime);

  /// Sisa waktu (untuk paket berbatas)
  Duration? get remaining {
    if (plannedEndTime == null) return null;
    final r = plannedEndTime!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// Apakah sesi hampir habis
  bool get isAlmostOver {
    if (remaining == null) return false;
    return remaining!.inMinutes < AppConstants.sessionWarningMinutes;
  }

  /// Apakah waktu paket sudah habis (menunggu checkout)
  bool get isExpired =>
      plannedEndTime != null && !DateTime.now().isBefore(plannedEndTime!);

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id:             json['id'] as String,
      unitId:         (json['unitId'] ?? json['unit_id']) as String,
      kasirId:        (json['kasirId'] ?? json['kasir_id']) as String,
      packageId:      (json['packageId'] ?? json['package_id']) as String?,
      startTime:      DateTime.parse((json['startTime'] ?? json['start_time']) as String),
      plannedEndTime: (json['plannedEndTime'] ?? json['planned_end_time']) != null
          ? DateTime.parse((json['plannedEndTime'] ?? json['planned_end_time']) as String)
          : null,
      endTime:        (json['endTime'] ?? json['end_time']) != null
          ? DateTime.parse((json['endTime'] ?? json['end_time']) as String)
          : null,
      durationMinutes: (json['durationMinutes'] ?? json['duration_minutes']) as int?,
      billingAmount:   (json['billingAmount'] ?? json['billing_amount']) != null
          ? ((json['billingAmount'] ?? json['billing_amount']) as num).toDouble()
          : null,
      posAmount:       (json['posAmount'] ?? json['pos_amount']) != null
          ? ((json['posAmount'] ?? json['pos_amount']) as num).toDouble()
          : null,
      extendedInfo:    (json['extendedInfo'] ?? json['extended_info']) as String?,
      status:   json['status'] as String,
      notes:    json['notes'] as String?,
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String).toLocal(),
      package:  json['package'] != null
          ? PackageModel.fromJson(json['package'] as Map<String, dynamic>)
          : null,
      kasir: json['kasir'] != null
          ? UserModel.fromJson(json['kasir'] as Map<String, dynamic>)
          : null,
      unit: json['unit'] != null
          ? UnitModel.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
    );
  }
}
