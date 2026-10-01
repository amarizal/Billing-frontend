class ReceiptModel {
  final String id;
  final String receiptNumber;
  final String? sessionId;
  final String? orderId;
  final String kasirId;
  final double billingAmount;
  final double posAmount;
  final double totalAmount;
  final String paymentMethod;
  final String printStatus;
  final DateTime createdAt;

  // Embedded
  final Map<String, dynamic>? session;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? kasir;

  const ReceiptModel({
    required this.id,
    required this.receiptNumber,
    this.sessionId,
    this.orderId,
    required this.kasirId,
    required this.billingAmount,
    required this.posAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.printStatus,
    required this.createdAt,
    this.session,
    this.order,
    this.kasir,
  });

  bool get isPrinted => printStatus == 'printed';

  String get displayTotal =>
      'Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id:            json['id'] as String? ?? '',
      receiptNumber: (json['receiptNumber'] ?? json['receipt_number']) as String? ?? '',
      sessionId:     (json['sessionId'] ?? json['session_id']) as String?,
      orderId:       (json['orderId'] ?? json['order_id']) as String?,
      kasirId:       (json['kasirId'] ?? json['kasir_id']) as String? ?? '',
      billingAmount: ((json['billingAmount'] ?? json['billing_amount']) as num?)?.toDouble() ?? 0.0,
      posAmount:     ((json['posAmount'] ?? json['pos_amount']) as num?)?.toDouble() ?? 0.0,
      totalAmount:   ((json['totalAmount'] ?? json['total_amount']) as num?)?.toDouble() ?? 0.0,
      paymentMethod: (json['paymentMethod'] ?? json['payment_method']) as String? ?? 'cash',
      printStatus:   (json['printStatus'] ?? json['print_status']) as String? ?? 'pending',
      createdAt:     DateTime.parse((json['createdAt'] ?? json['created_at']) as String? ?? DateTime.now().toIso8601String()).toLocal(),
      session:       json['session'] as Map<String, dynamic>?,
      order:         json['order'] as Map<String, dynamic>?,
      kasir:         json['kasir'] as Map<String, dynamic>?,
    );
  }
}
