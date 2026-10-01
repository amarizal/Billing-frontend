import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/package_provider.dart';
import 'checkout_dialog.dart';

class BillingTab extends StatefulWidget {
  const BillingTab({super.key});

  @override
  State<BillingTab> createState() => _BillingTabState();
}

class _BillingTabState extends State<BillingTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh timer setiap detik untuk update tampilan waktu
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<UnitProvider>().fetchUnits(),
      context.read<SessionProvider>().fetchActiveSessions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final units    = context.watch<UnitProvider>().units;
    final sessions = context.watch<SessionProvider>().activeSessions;
    final isLoading = context.watch<UnitProvider>().isLoading;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: CustomScrollView(
        slivers: [
          // Summary bar
          SliverToBoxAdapter(
            child: _SummaryBar(units: units, sessions: sessions),
          ),

          // Unit grid
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (context.watch<UnitProvider>().error != null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error: ${context.watch<UnitProvider>().error}\n\nTarik ke bawah untuk refresh',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            )
          else if (units.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Tidak ada unit PS yang tersedia.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _UnitCard(
                    unit: units[i],
                    session: sessions.where((s) => s.unitId == units[i].id).firstOrNull,
                  ),
                  childCount: units.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Summary Bar ────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<UnitModel> units;
  final List<SessionModel> sessions;
  const _SummaryBar({required this.units, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final available = units.where((u) => u.isAvailable).length;
    final inUse     = units.where((u) => u.isInUse).length;
    final maintenance = units.where((u) => u.isMaintenance).length;

    return Container(
      color: AppTheme.surface,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryChip(label: 'Tersedia', value: '$available', color: AppTheme.success),
            const SizedBox(width: 12),
            _SummaryChip(label: 'Bermain', value: '$inUse', color: AppTheme.primary),
            const SizedBox(width: 12),
            _SummaryChip(label: 'Maintenance', value: '$maintenance', color: AppTheme.warning),
            const SizedBox(width: 24),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$value $label',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─── Unit Card ──────────────────────────────────────────────

class _UnitCard extends StatelessWidget {
  final UnitModel unit;
  final SessionModel? session;
  const _UnitCard({required this.unit, this.session});

  Color get _statusColor {
    if (unit.isInUse) return AppTheme.success;
    if (unit.isMaintenance) return AppTheme.warning;
    return AppTheme.textMuted;
  }

  Color get _typeColor => unit.isPs5 ? AppTheme.ps5Accent : AppTheme.ps4Accent;

  String get _primaryTimeText {
    if (session == null) return '00:00:00';
    if (session!.plannedEndTime != null) {
      // Countdown
      final r = session!.remaining ?? Duration.zero;
      return '${r.inHours.toString().padLeft(2, '0')}:${(r.inMinutes % 60).toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      // Countup (Loss)
      final d = session!.elapsed;
      return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  String get _secondaryTimeText {
    if (session == null) return '';
    final timeStr = DateFormat('HH:mm').format(session!.startTime.toLocal());
    return 'Dimulai: $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isAlmostOver = session?.isAlmostOver ?? false;

    return Card(
      child: InkWell(
        onTap: () => _showUnitDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _typeColor.withOpacity(0.4)),
                    ),
                    child: Text(unit.type,
                        style: TextStyle(color: _typeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                      boxShadow: unit.isInUse
                          ? [BoxShadow(color: _statusColor.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Unit name
              Text(unit.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),

              // Status label
              Text(
                unit.isAvailable ? 'Tersedia' : unit.isInUse ? 'Sedang Bermain' : 'Maintenance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _statusColor),
              ),

              const Spacer(),

              if (unit.isInUse && session != null) ...[
                // Timer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: (isAlmostOver ? AppTheme.warning : AppTheme.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isAlmostOver ? AppTheme.warning : AppTheme.success).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _primaryTimeText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isAlmostOver ? AppTheme.warning : AppTheme.success,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (_secondaryTimeText.isNotEmpty)
                        Text(_secondaryTimeText,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (session?.package != null)
                  Text(
                    session!.package!.name,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: unit.isAvailable ? () => _showStartDialog(context) : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Mulai Sesi'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitDialog(BuildContext context) {
    if (unit.isInUse && session != null) {
      _showStopDialog(context);
    } else if (unit.isAvailable) {
      _showStartDialog(context);
    }
  }

  void _showStartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StartSessionSheet(unit: unit),
    );
  }

  void _showStopDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StopSessionSheet(
        unit: unit,
        session: session!,
        parentContext: context,
      ),
    );
  }
}

// ─── Start Session Bottom Sheet ─────────────────────────────

class StartSessionSheet extends StatefulWidget {
  final UnitModel unit;
  const StartSessionSheet({super.key, required this.unit});

  @override
  State<StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<StartSessionSheet> {
  String? _selectedPackageId;
  List<PackageModel> _packages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackages();
    });
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    final provider = context.read<PackageProvider>();
    await provider.fetchPackages();
    setState(() {
      _packages = provider.packages
          .where((p) => p.applicableTo == null || p.applicableTo == widget.unit.type)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _start() async {
    if (_selectedPackageId == null) return;
    final sessionProv = context.read<SessionProvider>();
    final unitProv    = context.read<UnitProvider>();

    final session = await sessionProv.startSession(widget.unit.id, _selectedPackageId!);
    if (!mounted) return;

    if (session != null) {
      unitProv.fetchUnits();
      Navigator.pop(context);
      
      if (sessionProv.tuyaWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesi dimulai, tapi: ${sessionProv.tuyaWarning}'),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesi dimulai untuk ${widget.unit.name}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memulai sesi'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Mulai Sesi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${widget.unit.name} · ${widget.unit.type}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('Pilih Paket', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),

          // Scrollable package list — agar tidak overflow jika paket banyak
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  else
                    ..._packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PackageOption(
                        package: pkg,
                        isSelected: _selectedPackageId == pkg.id,
                        onTap: () => setState(() => _selectedPackageId = pkg.id),
                      ),
                    )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedPackageId != null ? _start : null,
              child: const Text('Mulai Sesi'),
            ),
          ),
        ],
      ),
    );
  }
}


class _PackageOption extends StatelessWidget {
  final PackageModel package;
  final bool isSelected;
  final VoidCallback onTap;
  const _PackageOption({required this.package, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 16)),
                ],
              ),
            ),
            Text(package.displayPrice,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stop Session Bottom Sheet ───────────────────────────────

class StopSessionSheet extends StatefulWidget {
  final UnitModel unit;
  final SessionModel session;
  final BuildContext parentContext;

  const StopSessionSheet({
    super.key,
    required this.unit,
    required this.session,
    required this.parentContext,
  });

  @override
  State<StopSessionSheet> createState() => _StopSessionSheetState();
}

class _StopSessionSheetState extends State<StopSessionSheet> {
  bool _isStopping = false;

  Future<void> _stop() async {
    setState(() => _isStopping = true);
    try {
      final sessionProv = context.read<SessionProvider>();
      final unitProv    = context.read<UnitProvider>();

      final stopped = await sessionProv.stopSession(widget.session.id);
      if (!mounted) return;

      if (stopped != null) {
        unitProv.fetchUnits();
        final parentCtx = widget.parentContext;
        Navigator.pop(context); // Tutup dialog StopSessionSheet

        // Tampilkan Checkout Dialog dengan menggunakan parentContext
        if (parentCtx.mounted) {
          // Tampilkan warning jika ada
          if (sessionProv.tuyaWarning != null) {
            ScaffoldMessenger.of(parentCtx).showSnackBar(
              SnackBar(
                content: Text('Sesi dihentikan, tapi: ${sessionProv.tuyaWarning}'),
                backgroundColor: AppTheme.warning,
                duration: const Duration(seconds: 6),
              ),
            );
          }

          showDialog(
            context: parentCtx,
            barrierDismissible: false,
            builder: (_) => CheckoutDialog(
              sessionId: stopped.id,
              billingAmount: stopped.billingAmount ?? 0,
              posAmount: stopped.posAmount ?? 0,
              parentContext: parentCtx,
            ),
          );
        }
      } else {
        setState(() => _isStopping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghentikan sesi: ${sessionProv.error ?? "Terjadi kesalahan"}'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStopping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.session.elapsed;
    final elapsedStr =
        '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Hentikan Sesi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${widget.unit.name} · ${widget.unit.type}',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Text('Durasi Bermain',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(elapsedStr,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    )),
                if (widget.session.package != null) ...[
                  const SizedBox(height: 8),
                  Text('Paket: ${widget.session.package!.name}',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isStopping
                  ? null
                  : () {
                      Navigator.pop(context); // Tutup StopSessionSheet
                      _showExtendDialog(context);
                    },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Tambah Paket / Perpanjang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isStopping ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isStopping ? null : _stop,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  child: _isStopping
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Stop & Checkout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExtendDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExtendSessionSheet(unit: widget.unit, session: widget.session),
    );
  }
}

// ─── Extend Session Bottom Sheet ─────────────────────────────

class ExtendSessionSheet extends StatefulWidget {
  final UnitModel unit;
  final SessionModel session;
  const ExtendSessionSheet({super.key, required this.unit, required this.session});

  @override
  State<ExtendSessionSheet> createState() => _ExtendSessionSheetState();
}

class _ExtendSessionSheetState extends State<ExtendSessionSheet> {
  String? _selectedPackageId;
  List<PackageModel> _packages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackages();
    });
  }

  Future<void> _loadPackages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider = context.read<PackageProvider>();
    await provider.fetchPackages();
    if (!mounted) return;
    setState(() {
      _packages = provider.packages
          .where((p) => p.applicableTo == null || p.applicableTo == widget.unit.type)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _extend() async {
    if (_selectedPackageId == null) return;
    setState(() => _isLoading = true);
    try {
      final sessionProv = context.read<SessionProvider>();
      final unitProv    = context.read<UnitProvider>();

      final extended = await sessionProv.extendSession(widget.session.id, _selectedPackageId!);
      if (!mounted) return;

      if (extended != null) {
        unitProv.fetchUnits();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesi berhasil diperpanjang untuk ${widget.unit.name}'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperpanjang sesi: ${sessionProv.error ?? "Terjadi kesalahan"}'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Perpanjang Sesi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${widget.unit.name} · ${widget.unit.type} (Sesi Aktif)',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('Pilih Paket Tambahan', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),

          // Scrollable package list
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  else
                    ..._packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PackageOption(
                        package: pkg,
                        isSelected: _selectedPackageId == pkg.id,
                        onTap: () => setState(() => _selectedPackageId = pkg.id),
                      ),
                    )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedPackageId != null && !_isLoading ? _extend : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Konfirmasi Tambah Paket'),
            ),
          ),
        ],
      ),
    );
  }
}
