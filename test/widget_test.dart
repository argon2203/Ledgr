import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:ledgr/main.dart';
import 'package:ledgr/services/storage_service.dart';
import 'package:ledgr/providers/settings_provider.dart';
import 'package:ledgr/providers/ledger_provider.dart';
import 'package:ledgr/providers/voice_entry_provider.dart';

void main() {
  testWidgets('LedgrApp renders Home screen with core buttons and summary cards', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
          ChangeNotifierProvider(create: (_) => LedgerProvider(storageService)),
          ChangeNotifierProvider(create: (_) => VoiceEntryProvider()),
        ],
        child: const LedgrApp(),
      ),
    );

    // Pump frames without waiting indefinitely for the breathing mic animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Business Name in AppBar
    expect(find.text('OM TRADERS & WHOLESALE'), findsOneWidget);

    // Verify Bottom Navigation tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('Ask AI'), findsOneWidget);
    expect(find.text('Parties & Stock'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Today Summary Cards
    expect(find.text('Sales Today'), findsOneWidget);
    expect(find.text('To Collect'), findsOneWidget);
    expect(find.text('Low Stock Items'), findsOneWidget);
  });
}
