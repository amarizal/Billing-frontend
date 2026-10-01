import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/report_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/export_service.dart';
import '../../dashboard/receipt_dialog.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<ReportProvider>().fetchDailyReport(now);
      context.read<ReportProvider>().fetchMonthlyReport(now);
    });
  }

  Future<void> _deleteTransaction(String id, String? receiptNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Hapus Transaksi',
            style: TextStyle(color: AppTheme.danger)),
        content: Text(
            'Apakah Anda yakin ingin menghapus transaksi ${receiptNumber ?? '-'}?\n\nTindakan ini akan menghapus struk beserta sesi dan order POS yang terkait. Tindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ApiService>().deleteReceipt(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Transaksi berhasil dihapus'),
              backgroundColor: AppTheme.success));
          final now = DateTime.now();
          context.read<ReportProvider>().fetchDailyReport(now);
          context.read<ReportProvider>().fetchMonthlyReport(now);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final isAdmin = context.read<AuthProvider>().user?.role == 'admin';
    final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<ReportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.dailyReport == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.dailyReport == null) {
            return Center(
                child: Text(provider.error!,
                    style: const TextStyle(color: AppTheme.danger)));
          }

          final dailyReport = provider.dailyReport ?? {};
          final dailySummary = dailyReport['summary'] ?? {};
          final monthlyReport = provider.monthlyReport ?? {};
          final monthlySummary = monthlyReport['summary'] ?? {};

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle(
                'Laporan Hari Ini',
                onExportExcel: () => ExportService.exportToExcel(
                    dailyReport, 'Laporan Hari Ini', '${dateStr}_LH',
                    isDaily: true),
                onExportPdf: () => ExportService.exportToPdf(
                    dailyReport, 'Laporan Hari Ini', '${dateStr}_LH',
                    isDaily: true),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryCard(
                          'Total Pendapatan',
                          _currency.format(dailySummary['totalAmount'] ?? 0),
                          Icons.monetization_on,
                          AppTheme.success)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSummaryCard(
                          'Pendapatan Billing',
                          _currency.format(dailySummary['totalBilling'] ?? 0),
                          Icons.sports_esports,
                          AppTheme.primary)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSummaryCard(
                          'Pendapatan POS',
                          _currency.format(dailySummary['totalPos'] ?? 0),
                          Icons.restaurant,
                          AppTheme.secondary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryCard(
                          'Sesi/Struk Tercetak',
                          '${dailySummary['totalTransactions'] ?? 0}',
                          Icons.receipt,
                          AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Riwayat Transaksi Hari Ini',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (dailyReport['receipts'] != null &&
                  (dailyReport['receipts'] as List).isNotEmpty)
                ...((dailyReport['receipts'] as List).reversed.map((r) {
                  return Card(
                    color: AppTheme.surfaceElevated,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child:
                            Icon(Icons.receipt, color: Colors.white, size: 20),
                      ),
                      title: Text(r['receiptNumber'] ?? '-',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${DateFormat('HH:mm').format(DateTime.parse(r['createdAt']).toLocal())} • Kasir: ${r['kasir']?['name'] ?? '-'}',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _currency.format(
                                  (r['totalAmount'] as num?)?.toDouble() ?? 0),
                              style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold)),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppTheme.danger, size: 20),
                              onPressed: () => _deleteTransaction(
                                  r['id'], r['receiptNumber']),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => ReceiptDialog(receiptId: r['id']),
                        );
                      },
                    ),
                  );
                }).toList())
              else
                const Text('Belum ada transaksi hari ini',
                    style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              _buildSectionTitle(
                'Laporan Bulan Ini',
                onExportExcel: () => ExportService.exportToExcel(
                    monthlyReport, 'Laporan Bulan Ini', '${dateStr}_LB',
                    isDaily: false),
                onExportPdf: () => ExportService.exportToPdf(
                    monthlyReport, 'Laporan Bulan Ini', '${dateStr}_LB',
                    isDaily: false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryCard(
                          'Total Pendapatan',
                          _currency.format(monthlySummary['totalAmount'] ?? 0),
                          Icons.monetization_on,
                          AppTheme.success)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSummaryCard(
                          'Pendapatan Billing',
                          _currency.format(monthlySummary['totalBilling'] ?? 0),
                          Icons.sports_esports,
                          AppTheme.primary)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSummaryCard(
                          'Pendapatan POS',
                          _currency.format(monthlySummary['totalPos'] ?? 0),
                          Icons.restaurant,
                          AppTheme.secondary)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      {VoidCallback? onExportExcel, VoidCallback? onExportPdf}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onExportExcel,
              icon:
                  const Icon(Icons.table_chart, color: Colors.green, size: 18),
              label: const Text('Excel', style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onExportPdf,
              icon:
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
              label: const Text('PDF', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color iconColor) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
