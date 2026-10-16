import 'package:flutter/material.dart';
import 'core/database/database_service.dart';
import 'core/theme/kwall_theme.dart';
import 'features/bodega/presentation/bodega_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database with desktop/mobile FFI
  await DatabaseService.instance.database;

  runApp(const KwallApp());
}

class KwallApp extends StatelessWidget {
  const KwallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kwall — Kitty Wallet',
      debugShowCheckedModeBanner: false,
      theme: KwallTheme.darkTheme,
      home: const BodegaScreen(),
    );
  }
}
