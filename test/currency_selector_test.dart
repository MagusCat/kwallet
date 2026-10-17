import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/app/app_dependencies.dart';
import 'package:kwall/app/app_scope.dart';
import 'package:kwall/core/database/database_service.dart';
import 'package:kwall/core/theme/kwall_theme.dart';
import 'package:kwall/core/services/device_files.dart';
import 'package:kwall/core/widgets/currency_selector.dart';
import 'package:kwall/features/bodega/presentation/add_account_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('Account currency selection works without text input on compact and wide screens', (tester) async {
    sqfliteFfiInit();
    final service = DatabaseService.atPath(inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
    await tester.runAsync(() async {
      await service.setCurrencyRate(currency: 'NIO', rate: 0.025);
      if (const bool.fromEnvironment('KWALL_CAPTURE')) {
        final config = File('.dart_tool/package_config.json').absolute;
        final packages = (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
        final flutter = packages.firstWhere((p) => p['name'] == 'flutter') as Map;
        final root = Directory.fromUri(config.uri.resolve(flutter['rootUri'] as String)).parent.parent.path;
        for (final entry in {'Roboto': 'Roboto-Regular.ttf', 'MaterialIcons': 'MaterialIcons-Regular.otf'}.entries) {
          final loader = FontLoader(entry.key);
          loader.addFont(File('$root/bin/cache/artifacts/material_fonts/${entry.value}').readAsBytes().then(ByteData.sublistView));
          await loader.load();
        }
      }
    });
    addTearDown(() async => (await service.database).close());
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey();
    for (final size in [const Size(390, 844), const Size(1024, 900)]) {
      for (final mode in ['light', 'dark']) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        KwallTheme.configure({'theme_mode': mode}, Brightness.light);
        await tester.pumpWidget(AppScope(dependencies: AppDependencies(finance: service, journal: service, settings: service, files: NativeDeviceFiles()),
          child: MaterialApp(theme: KwallTheme.expressiveTheme, home: RepaintBoundary(key: key, child: const Scaffold(body: AddAccountDialog(currency: 'USD'))))));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
        expect(find.byType(CurrencySelector), findsOneWidget);
        expect(find.text('Moneda principal en la que opera esta cuenta.'), findsNothing);
        await tester.tap(find.byType(CurrencySelector));
        await tester.pumpAndSettle();
        await tester.tap(find.text('NIO · Córdoba').last);
        await tester.pumpAndSettle();
        final field = tester.widget<DropdownButtonFormField<String>>(find.descendant(of: find.byType(CurrencySelector), matching: find.byType(DropdownButtonFormField<String>)));
        expect(field.initialValue, 'NIO');
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('KWALL_CAPTURE')) {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('.impeccable/review/account-${size.width.toInt()}-$mode.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
    KwallTheme.configure({'theme_mode': 'light'}, Brightness.light);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
