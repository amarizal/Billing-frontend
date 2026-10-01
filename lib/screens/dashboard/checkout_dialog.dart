import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/report_provider.dart';
import 'receipt_dialog.dart';

class CheckoutDialog extends StatefulWidget {
  final String? sessionId;
  final String? orderId;
  final double billingAmount;
  final double posAmount;
  final BuildContext parentContext;

  const CheckoutDialog({
    super.key,
    this.sessionId,
    this.orderId,
    required this.billingAmount,
    required this.posAmount,
    required this.parentContext,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _paymentMethod = 'cash';
  bool _isProcessing = false;

  double get _total => widget.billingAmount + widget.posAmount;

  String _formatRp(double val) =>
      'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.createReceipt({
        if (widget.sessionId != null) 'sessionId': widget.sessionId,
        if (widget.orderId != null) 'orderId': widget.orderId,
        'paymentMethod': _paymentMethod,
        'printStatus': 'digital_only',
      });

      if (!mounted) return;

      if (res['success'] == true) {
        // Refresh Report Data agar Laporan Hari Ini langsung update
        final now = DateTime.now();
        context.read<ReportProvider>().fetchDailyReport(now);
        context.read<ReportProvider>().fetchMonthlyReport(now);

        final parentCtx = widget.parentContext;
        Navigator.pop(context, true); // Tutup dialog checkout
        
        // Tampilkan Struk Digital dengan menggunakan parentContext
        if (parentCtx.mounted) {
          showDialog(
            context: parentCtx,
            barrierDismissible: false,
            builder: (_) => ReceiptDialog(receiptId: res['data']['id']),
          );
        }
      } else {
        throw Exception(res['message'] ?? 'Gagal membuat struk');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_checkout, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text('Checkout', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            const Divider(height: 32),

            // Ringkasan
            const Text('Ringkasan Tagihan', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            if (widget.billingAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sesi PS'),
                  Text(_formatRp(widget.billingAmount)),
                ],
              ),
            if (widget.billingAmount > 0 && widget.posAmount > 0)
              const SizedBox(height: 8),
            if (widget.posAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Item POS'),
                  Text(_formatRp(widget.posAmount)),
                ],
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppTheme.border),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  _formatRp(_total),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppTheme.primary),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Metode Pembayaran
            const Text('Metode Pembayaran', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.money,
                    label: 'Tunai / Cash',
                    isSelected: _paymentMethod == 'cash',
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.qr_code_2,
                    label: 'QRIS',
                    isSelected: _paymentMethod == 'qris',
                    onTap: () => setState(() => _paymentMethod = 'qris'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Konfirmasi & Bayar'),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
