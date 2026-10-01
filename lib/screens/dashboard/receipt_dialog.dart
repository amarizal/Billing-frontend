import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/receipt_model.dart';
import '../../core/services/api_service.dart';

class ReceiptDialog extends StatefulWidget {
  final String receiptId;

  const ReceiptDialog({super.key, required this.receiptId});

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  ReceiptModel? _receipt;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    try {
      final res = await context.read<ApiService>().getReceipt(widget.receiptId);
      if (res['data'] != null) {
        if (mounted) {
          setState(() {
            _receipt = ReceiptModel.fromJson(res['data'] as Map<String, dynamic>);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Data struk tidak ditemukan');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatRp(dynamic val) {
    if (val == null) return 'Rp 0';
    final numValue =
        val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
    return 'Rp ${numValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white, // Kertas struk biasanya putih
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 200, child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? SizedBox(
                    height: 200,
                    child: Center(
                        child: Text('Error: $_error',
                            style: const TextStyle(color: Colors.red))))
                : receipt == null
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: Text('Struk kosong atau tidak valid')))
                    : Column(
                        children: [
                          // Isi Struk
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long,
                                      size: 48, color: Colors.black87),
                                  const SizedBox(height: 16),
                                  const Text('Afone Playstation',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const Text(
                                      'Jl. Raya Panyileukan No.10, Cipadung Kidul, Kec. Panyileukan, Kota Bandung, Jawa Barat 40614',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 24),

                                  _buildDottedLine(),
                                  const SizedBox(height: 12),

                                  // Info Transaksi
                                  _buildInfoRow('No.', receipt.receiptNumber),
                                  _buildInfoRow(
                                      'Tgl.',
                                      DateFormat('dd MMM yyyy HH:mm')
                                          .format(receipt.createdAt)),
                                  _buildInfoRow('Kasir',
                                      receipt.kasir?['name'] ?? 'System'),

                                  const SizedBox(height: 12),
                                  _buildDottedLine(),
                                  const SizedBox(height: 12),

                                  // Sesi PS
                                  if (receipt.session != null) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('RENTAL PS:',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  '${receipt.session?['unit']?['name'] ?? 'Unit'} (${receipt.session?['unit']?['type'] ?? ''})',
                                                  style: const TextStyle(
                                                      color: Colors.black)),
                                              if (receipt.session?['extendedInfo'] != null &&
                                                  receipt.session?['extendedInfo']?.toString().isNotEmpty == true)
                                                Text(
                                                    'Paket: ${receipt.session?['extendedInfo']}',
                                                    style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 12))
                                              else if (receipt.session?['extended_info'] != null &&
                                                  receipt.session?['extended_info']?.toString().isNotEmpty == true)
                                                Text(
                                                    'Paket: ${receipt.session?['extended_info']}',
                                                    style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 12))
                                              else if (receipt.session?['package'] != null)
                                                Text(
                                                    'Paket: ${receipt.session?['package']?['name'] ?? ''}',
                                                    style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Text(_formatRp(receipt.billingAmount),
                                            style: const TextStyle(
                                                color: Colors.black)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Item POS
                                  if (receipt.order != null &&
                                      receipt.order?['items'] != null) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('F&B / SNACK:',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.from(receipt.order?['items'] ?? []).map((e) {
                                      final item = e as Map<String, dynamic>;
                                      final itemName = item['itemName'] ?? item['item_name'] ?? 'Item';
                                      final quantity = item['quantity'] ?? item['qty'] ?? 0;
                                      final unitPrice = item['unitPrice'] ?? item['unit_price'] ?? 0.0;
                                      final subtotal = item['subtotal'] ?? 0.0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(itemName,
                                                      style: const TextStyle(
                                                          color: Colors.black)),
                                                  Text(
                                                      '$quantity x ${_formatRp(unitPrice)}',
                                                      style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            Text(_formatRp(subtotal),
                                                style: const TextStyle(
                                                    color: Colors.black)),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                  ],

                                  _buildDottedLine(),
                                  const SizedBox(height: 12),

                                  // Total
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('TOTAL',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      Text(_formatRp(receipt.totalAmount),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Pembayaran',
                                          style: TextStyle(color: Colors.black54)),
                                      Text(receipt.paymentMethod.toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.black54)),
                                    ],
                                  ),

                                  const SizedBox(height: 32),
                                  const Text('Terima Kasih!',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  const Text(
                                      'Barang yang sudah dibeli tidak dapat ditukar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),

                          // Action Buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(color: Colors.black26),
                                    ),
                                    child: const Text('Tutup'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Integrasi Printer Bluetooth
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Printer belum dikonfigurasi')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text('Print Fisik'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black38)),
            );
          }),
        );
      },
    );
  }
}
