import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/pos_provider.dart';
import '../../../core/models/pos_category_model.dart';

class AdminPosTab extends StatefulWidget {
  const AdminPosTab({super.key});

  @override
  State<AdminPosTab> createState() => _AdminPosTabState();
}

class _AdminPosTabState extends State<AdminPosTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().fetchCategories();
    });
  }

  void _showCategoryDialog([PosCategoryModel? category]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
    );
  }

  void _showItemDialog([PosItemModel? item]) {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: const TabBar(
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: [
                Tab(text: 'Item / Menu'),
                Tab(text: 'Kategori'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildItemsView(),
                _buildCategoriesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<PosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.categories.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              return Card(
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(cat.name, style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
                    onPressed: () => _showCategoryDialog(cat),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cat',
        backgroundColor: AppTheme.primary,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDeleteItem(PosItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Item?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Yakin ingin menghapus ${item.name}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<PosProvider>().deleteItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<PosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = provider.categories.expand((c) => c.items).toList();
          
          if (items.isEmpty) {
            return const Center(
              child: Text('Belum ada item.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final flatItems = provider.categories.expand((c) => c.items).toList();
              final item = flatItems.removeAt(oldIndex);
              flatItems.insert(newIndex, item);
              provider.reorderItems(flatItems);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final category = provider.categories.firstWhere((c) => c.id == item.categoryId, orElse: () => PosCategoryModel(id: '', name: 'Unknown', displayOrder: 0, isActive: true));
              return Card(
                key: ValueKey(item.id),
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(item.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${category.name} • ${item.displayPrice}${item.stock != null ? ' • Stok: ${item.stock}' : ''}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.textSecondary, size: 20),
                        onPressed: () => _showItemDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.danger, size: 20),
                        onPressed: () => _confirmDeleteItem(item),
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
        heroTag: 'fab_item',
        backgroundColor: AppTheme.secondary,
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final PosCategoryModel? category;
  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = context.read<PosProvider>();
    final data = {'name': _nameController.text};
    bool success;
    if (widget.category == null) {
      success = await provider.createCategory(data);
    } else {
      success = await provider.updateCategory(widget.category!.id, data);
    }
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori', style: const TextStyle(color: AppTheme.textPrimary)),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Nama Kategori', labelStyle: TextStyle(color: AppTheme.textSecondary)),
          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: _isLoading ? null : _submit,
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  final PosItemModel? item;
  const _ItemFormDialog({this.item});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String? _categoryId;
  bool _isLoading = false;
  bool _useStock = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toInt().toString() ?? '');
    _stockController = TextEditingController(text: widget.item?.stock?.toString() ?? '0');
    _useStock = widget.item?.stock != null;
    _categoryId = widget.item?.categoryId;
    if (_categoryId == null || _categoryId!.isEmpty) {
      final categories = context.read<PosProvider>().categories;
      if (categories.isNotEmpty) _categoryId = categories.first.id;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _isLoading = true);
    final provider = context.read<PosProvider>();
    final data = {
      'name': _nameController.text,
      'categoryId': _categoryId,
      'price': double.parse(_priceController.text),
      'stock': _useStock ? int.tryParse(_stockController.text) ?? 0 : null,
    };
    bool success;
    if (widget.item == null) {
      success = await provider.createItem(data);
    } else {
      success = await provider.updateItem(widget.item!.id, data);
    }
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<PosProvider>().categories;
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(widget.item == null ? 'Tambah Item' : 'Edit Item', style: const TextStyle(color: AppTheme.textPrimary)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Nama Item', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoryId,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Kategori', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga (Rp)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kelola Stok', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                value: _useStock,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _useStock = v),
              ),
              if (_useStock)
                TextFormField(
                  controller: _stockController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah Stok Sisa', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                  validator: (v) => _useStock && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: _isLoading ? null : _submit,
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
