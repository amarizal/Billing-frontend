import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/package_provider.dart';
import '../../../core/models/package_model.dart';

class AdminPackagesTab extends StatefulWidget {
  const AdminPackagesTab({super.key});

  @override
  State<AdminPackagesTab> createState() => _AdminPackagesTabState();
}

class _AdminPackagesTabState extends State<AdminPackagesTab> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchPackages();
    });
  }

  void _showPackageDialog([PackageModel? pkg]) {
    showDialog(
      context: context,
      builder: (context) => _PackageFormDialog(pkg: pkg),
    );
  }

  void _confirmDelete(PackageModel pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Paket?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Yakin ingin menghapus ${pkg.name}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<PackageProvider>().deletePackage(pkg.id);
              setState(() {
                _selectedIds.remove(pkg.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Paket Terpilih?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Yakin ingin menghapus ${_selectedIds.length} paket terpilih?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              final provider = context.read<PackageProvider>();
              final ids = _selectedIds.toList();
              for (final id in ids) {
                await provider.deletePackage(id);
              }
              setState(() {
                _selectedIds.clear();
                _isDeleting = false;
              });
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _selectedIds.isEmpty
          ? null
          : AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              title: Text(
                '${_selectedIds.length} Paket Terpilih',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.danger),
                  onPressed: _confirmDeleteSelected,
                ),
              ],
            ),
      body: Consumer<PackageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.packages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.packages.isEmpty) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            );
          }

          if (provider.packages.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada paket billing.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.packages.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final items = List<PackageModel>.from(provider.packages);
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              provider.reorderPackages(items);
            },
            itemBuilder: (context, index) {
              final pkg = provider.packages[index];
              final isSelected = _selectedIds.contains(pkg.id);
              return Card(
                key: ValueKey(pkg.id),
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(pkg.id);
                            } else {
                              _selectedIds.remove(pkg.id);
                            }
                          });
                        },
                      ),
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Icon(
                          pkg.type == 'hourly' ? Icons.timer : Icons.inventory_2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  title: Text(pkg.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    pkg.type == 'hourly' ? 'Per Jam • ${pkg.displayPrice}' : '${pkg.durationMinutes} Menit • ${pkg.displayPrice}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.textSecondary, size: 20),
                        onPressed: () => _showPackageDialog(pkg),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.danger, size: 20),
                        onPressed: () => _confirmDelete(pkg),
                      ),
                      const SizedBox(width: 4),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.reorder, color: AppTheme.textMuted),
                      ),
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
        onPressed: () => _showPackageDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PackageFormDialog extends StatefulWidget {
  final PackageModel? pkg;
  const _PackageFormDialog({this.pkg});

  @override
  State<_PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<_PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  String _type = 'package'; // 'package' | 'hourly'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pkg?.name ?? '');
    _priceController = TextEditingController(text: widget.pkg != null ? widget.pkg!.price.toInt().toString() : '');
    _durationController = TextEditingController(text: widget.pkg != null ? widget.pkg!.durationMinutes.toString() : '');
    if (widget.pkg != null) {
      _type = widget.pkg!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final provider = context.read<PackageProvider>();
    final data = {
      'name': _nameController.text,
      'type': _type,
      'price': double.parse(_priceController.text),
      'durationMinutes': _type == 'hourly' ? 0 : int.parse(_durationController.text),
    };

    bool success;
    if (widget.pkg == null) {
      success = await provider.createPackage(data);
    } else {
      success = await provider.updatePackage(widget.pkg!.id, data);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Gagal menyimpan paket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        widget.pkg == null ? 'Tambah Paket' : 'Edit Paket',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nama Paket',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textMuted)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                ),
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Tipe Paket',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textMuted)),
                ),
                items: const [
                  DropdownMenuItem(value: 'package', child: Text('Paket Tetap')),
                  DropdownMenuItem(value: 'hourly', child: Text('Per Jam (Tanpa Batas)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textMuted)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga wajib diisi';
                  if (double.tryParse(v) == null) return 'Harga tidak valid';
                  return null;
                },
              ),
              if (_type == 'package') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durasi (Menit)',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textMuted)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Durasi wajib diisi';
                    if (int.tryParse(v) == null) return 'Durasi tidak valid';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
