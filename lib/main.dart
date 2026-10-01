import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/unit_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/pos_provider.dart';
import 'core/providers/package_provider.dart';
import 'core/providers/report_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/services/api_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(BillingPosApp(prefs: prefs));
}

class BillingPosApp extends StatelessWidget {
  final SharedPreferences prefs;
  const BillingPosApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (ctx) => AuthProvider(ctx.read<ApiService>(), prefs)),
        ChangeNotifierProvider(create: (ctx) => UnitProvider(ctx.read<ApiService>())),
        ChangeNotifierProvider(create: (ctx) => SessionProvider(ctx.read<ApiService>())),
        ChangeNotifierProvider(create: (ctx) => PosProvider(ctx.read<ApiService>())),
        ChangeNotifierProvider(create: (ctx) => PackageProvider(ctx.read<ApiService>())),
        ChangeNotifierProvider(create: (ctx) => ReportProvider(ctx.read<ApiService>())),
        ChangeNotifierProvider(create: (ctx) => UserProvider(ctx.read<ApiService>())),
      ],
      child: MaterialApp(
        title: 'Billing System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
