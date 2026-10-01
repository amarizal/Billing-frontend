import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/user_provider.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  void _showUserDialog([UserModel? user]) {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(user: user),
    );
  }

  void _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Nonaktifkan Akun?'),
        content: Text('Apakah Anda yakin ingin menonaktifkan akun ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<UserProvider>().deleteUser(user.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dinonaktifkan'), backgroundColor: AppTheme.success),
        );
      } else {
        final error = context.read<UserProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Gagal menonaktifkan akun'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Akun'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.users.isEmpty) {
            return Center(
              child: Text(provider.error!, style: const TextStyle(color: AppTheme.danger)),
            );
          }

          if (provider.users.isEmpty) {
            return const Center(
              child: Text('Belum ada akun yang terdaftar', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: provider.users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return Card(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: user.isAdmin ? AppTheme.ps5Accent.withOpacity(0.2) : AppTheme.primary.withOpacity(0.2),
                    child: Icon(
                      user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: user.isAdmin ? AppTheme.ps5Accent : AppTheme.primary,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(user.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isActive ? AppTheme.success.withOpacity(0.2) : AppTheme.danger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: user.isActive ? AppTheme.success : AppTheme.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('@${user.username} • Role: ${user.role.toUpperCase()}', 
                    style: const TextStyle(color: AppTheme.textSecondary)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
                        onPressed: () => _showUserDialog(user),
                        tooltip: 'Edit Akun',
                      ),
                      if (user.isActive)
                        IconButton(
                          icon: const Icon(Icons.person_off_outlined, color: AppTheme.danger),
                          onPressed: () => _confirmDelete(user),
                          tooltip: 'Nonaktifkan',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final UserModel? user;
  const _UserFormDialog({this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  String _role = 'kasir';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameCtrl.text = widget.user!.name;
      _usernameCtrl.text = widget.user!.username;
      _role = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text,
      'username': _usernameCtrl.text,
      'role': _role,
      'isActive': _isActive,
    };
    
    // Hanya kirim password jika diisi (opsional untuk edit, wajib untuk add)
    if (_passwordCtrl.text.isNotEmpty) {
      data['password'] = _passwordCtrl.text;
    }

    final provider = context.read<UserProvider>();
    bool success;
    
    if (widget.user == null) {
      success = await provider.createUser(data);
    } else {
      success = await provider.updateUser(widget.user!.id, data);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.user == null ? 'Akun berhasil ditambahkan' : 'Akun berhasil diperbarui'), backgroundColor: AppTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Gagal menyimpan akun'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    
    return AlertDialog(
      backgroundColor: AppTheme.surfaceElevated,
      title: Text(isEdit ? 'Edit Akun' : 'Tambah Akun', style: const TextStyle(color: AppTheme.textPrimary)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                ),
                validator: (v) => (!isEdit && v!.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _role,
                dropdownColor: AppTheme.surfaceElevated,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Role Akun',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              if (isEdit) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Akun Aktif', style: TextStyle(color: AppTheme.textPrimary)),
                  value: _isActive,
                  activeColor: AppTheme.success,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
