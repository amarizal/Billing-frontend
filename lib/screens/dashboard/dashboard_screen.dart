import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../login_screen.dart';
import 'billing_tab.dart';
import 'pos_tab.dart';
import '../admin/admin_screen.dart';
import '../admin/tabs/admin_reports_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitProvider>().fetchUnits();
      context.read<SessionProvider>().fetchActiveSessions();
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final isLargeScreen = MediaQuery.of(context).size.width >= 720;

    final tabs = [
      const BillingTab(),
      const PosTab(),
      const AdminReportsTab(),
      if (isAdmin) const AdminScreen(),
    ];

    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.timer_outlined),
        selectedIcon: Icon(Icons.timer_rounded),
        label: Text('Billing'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale_rounded),
        label: Text('Kasir'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded),
        label: Text('Laporan'),
      ),
      if (isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded),
          label: Text('Admin'),
        ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('Billing System', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isAdmin ? AppTheme.ps5Accent : AppTheme.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isAdmin ? AppTheme.ps5Accent : AppTheme.primary).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Kasir',
                    style: TextStyle(
                      color: isAdmin ? AppTheme.ps5Accent : AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    auth.user?.name ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLargeScreen
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppTheme.surface,
                  selectedIconTheme: const IconThemeData(color: AppTheme.primary),
                  selectedLabelTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  unselectedIconTheme: const IconThemeData(color: AppTheme.textMuted),
                  unselectedLabelTextStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  destinations: railDestinations,
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppTheme.border),
                Expanded(child: tabs[_selectedIndex]),
              ],
            )
          : tabs[_selectedIndex],
      bottomNavigationBar: isLargeScreen
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.timer_outlined),
                    activeIcon: Icon(Icons.timer_rounded),
                    label: 'Billing',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.point_of_sale_outlined),
                    activeIcon: Icon(Icons.point_of_sale_rounded),
                    label: 'Kasir',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined),
                    activeIcon: Icon(Icons.analytics_rounded),
                    label: 'Laporan',
                  ),
                  if (isAdmin)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      activeIcon: Icon(Icons.admin_panel_settings_rounded),
                      label: 'Admin',
                    ),
                ],
              ),
            ),
    );
  }
}
