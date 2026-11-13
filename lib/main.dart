import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/colors.dart';
import 'core/constants/strings.dart';
import 'core/constants/theme.dart';
import 'services/storage_service.dart';
import 'providers/settings_provider.dart';
import 'providers/ledger_provider.dart';
import 'providers/voice_entry_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/entries/entries_screen.dart';
import 'screens/ask/ask_screen.dart';
import 'screens/parties_stock/parties_stock_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => LedgerProvider(storageService)),
        ChangeNotifierProvider(create: (_) => VoiceEntryProvider()),
      ],
      child: const LedgrApp(),
    ),
  );
}

class LedgrApp extends StatelessWidget {
  const LedgrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Ledgr',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    EntriesScreen(),
    AskScreen(),
    PartiesStockScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    Provider.of<SettingsProvider>(context); // Trigger rebuild on language change

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryContainer,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: AppStrings.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long, color: AppColors.primary),
              label: AppStrings.tabEntries,
            ),
            NavigationDestination(
              icon: const Icon(Icons.question_answer_outlined),
              selectedIcon: const Icon(Icons.question_answer, color: AppColors.primary),
              label: AppStrings.tabAsk,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_alt_outlined),
              selectedIcon: const Icon(Icons.people_alt, color: AppColors.primary),
              label: AppStrings.tabPartiesStock,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
              label: AppStrings.tabSettings,
            ),
          ],
        ),
      ),
    );
  }
}
