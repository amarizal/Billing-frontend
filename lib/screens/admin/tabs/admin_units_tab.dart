import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/unit_provider.dart';
import '../../../core/models/unit_model.dart';

class AdminUnitsTab extends StatefulWidget {
  const AdminUnitsTab({super.key});

  @override
  State<AdminUnitsTab> createState() => _AdminUnitsTabState();
}

class _AdminUnitsTabState extends State<AdminUnitsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitProvider>().fetchUnits();
    });
  }

  void _showUnitDialog([UnitModel? unit]) {
    showDialog(
      context: context,
      builder: (context) => _UnitFormDialog(unit: unit),
    );
  }

  void _confirmDelete(UnitModel unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Unit?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Yakin ingin menghapus ${unit.name}?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<UnitProvider>().deleteUnit(unit.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<UnitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.units.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.units.isEmpty) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            );
          }

          if (provider.units.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada unit PS.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.units.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final items = List<UnitModel>.from(provider.units);
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              
              final success = await provider.reorderUnits(items);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Gagal memperbarui urutan'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              }
            },
            itemBuilder: (context, index) {
              final unit = provider.units[index];
              return Card(
                key: ValueKey(unit.id),
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: unit.isPs5
                        ? AppTheme.primary.withOpacity(0.2)
                        : AppTheme.secondary.withOpacity(0.2),
                    child: Icon(
                      Icons.sports_esports,
                      color: unit.isPs5 ? AppTheme.primary : AppTheme.secondary,
                    ),
                  ),
                  title: Text(unit.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${unit.type} • Status: ${unit.status}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme.textSecondary),
                        onPressed: () => _showUnitDialog(unit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.danger),
                        onPressed: () => _confirmDelete(unit),
                      ),
                      const Icon(Icons.drag_handle, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showUnitDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _UnitFormDialog extends StatefulWidget {
  final UnitModel? unit;
  const _UnitFormDialog({this.unit});

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipAddressController;
  late TextEditingController _tuyaDeviceIdController;
  String _type = 'PS4';
  int _displayOrder = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _ipAddressController = TextEditingController(text: widget.unit?.ipAddress ?? '');
    _tuyaDeviceIdController = TextEditingController(text: widget.unit?.tuyaDeviceId ?? '');
    if (widget.unit != null) {
      _type = widget.unit!.type;
      _displayOrder = widget.unit!.displayOrder;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipAddressController.dispose();
    _tuyaDeviceIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<UnitProvider>();
    final data = {
      'name': _nameController.text,
      'type': _type,
      'displayOrder': _displayOrder,
      'ipAddress': _ipAddressController.text.trim(),
      'tuyaDeviceId': _tuyaDeviceIdController.text.trim(),
    };

    bool success;
    if (widget.unit == null) {
      success = await provider.createUnit(data);
    } else {
      success = await provider.updateUnit(widget.unit!.id, data);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Gagal menyimpan unit')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        widget.unit == null ? 'Tambah Unit PS' : 'Edit Unit PS',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nama Unit (misal: PS4 Unit 1)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.textMuted)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
              validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipAddressController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'IP Address TV Lokal (Opsional)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.textMuted)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tuyaDeviceIdController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Tuya Device ID (Opsional)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                hintText: 'Misal: a3c00efb89d5bb59d8mtd2',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.textMuted)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: AppTheme.surface,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Tipe Konsol',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.textMuted)),
              ),
              items: const [
                DropdownMenuItem(value: 'PS4', child: Text('PlayStation 4')),
                DropdownMenuItem(value: 'PS5', child: Text('PlayStation 5')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
