import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import 'tabs/admin_units_tab.dart';
import 'tabs/admin_packages_tab.dart';
import 'tabs/admin_pos_tab.dart';
import 'tabs/admin_users_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    // Validasi Role Admin
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security_update_warning, size: 80, color: AppTheme.danger),
              const SizedBox(height: 16),
              const Text('Akses Ditolak', style: TextStyle(color: AppTheme.danger, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Halaman ini khusus untuk Administrator.', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: const TabBar(
              isScrollable: true,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: [
                Tab(text: 'Unit PS'),
                Tab(text: 'Paket'),
                Tab(text: 'Menu POS'),
                Tab(text: 'Kasir & Akun'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdminUnitsTab(),
                AdminPackagesTab(),
                AdminPosTab(),
                AdminUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
