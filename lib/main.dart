import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_dependencies.dart';
import 'app/app_scope.dart';
import 'app/app_view_model.dart';
import 'core/theme/kwall_theme.dart';
import 'features/welcome/presentation/launch_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KwallApp());
}

class KwallApp extends StatefulWidget {
  final AppDependencies? dependencies;
  const KwallApp({super.key, this.dependencies});
  @override
  State<KwallApp> createState() => _KwallAppState();
}

class _KwallAppState extends State<KwallApp> with WidgetsBindingObserver {
  late final _dependencies = widget.dependencies ?? AppDependencies.local();
  late final AppViewModel _model = _dependencies.app();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model.addListener(_appearance);
    _appearance();
  }

  void _appearance() {
    KwallTheme.configure(
      _model.settings,
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void didChangePlatformBrightness() => _appearance();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.removeListener(_appearance);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: KwallTheme.revision,
    builder: (_, value, child) => AppScope(
      dependencies: _dependencies,
      child: MaterialApp(
        title: 'kwall',
        debugShowCheckedModeBanner: false,
        theme: KwallTheme.expressiveTheme,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => AnimatedTheme(
          data: KwallTheme.expressiveTheme,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const LaunchScreen(),
      ),
    ),
  );
}
