import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/counter_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/counter_display.dart';
import 'widgets/controls.dart';
import 'screens/saved.dart';
import 'screens/settings.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Click Counter',
          theme: ThemeData(
            // App buttons and primary color
            primarySwatch: Colors.blue,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData.dark(), // Dark theme
          themeMode: settings.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light, // Use theme based on settings
          home: const MyHomePage(),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  // no cached pages: build children dynamically so they react to provider changes
  bool _didPromptForName = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely access SettingsProvider and prompt for a name once if not
    // already prompted. Use the persistent `namePrompted` flag so we don't
    // keep asking after the user skipped or saved.
    if (!_didPromptForName) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      // Wait until the provider has loaded from SharedPreferences.
      if (!settings.initialized) return;

      if (!settings.namePrompted &&
          (settings.userName == null || settings.userName!.isEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final controller = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                'Welcome to Click Counter!\nWhat is your name?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Skip'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (ok == true) {
            settings.userName = controller.text.trim();
          }
          settings.namePrompted = true;
        });
      }
      _didPromptForName = true;
    }
  }

  Widget _buildHomeTab(SettingsProvider settings) {
    final name = (settings.userName == null || settings.userName!.isEmpty)
        ? 'Friend'
        : settings.userName!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hello $name!',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          const CounterDisplay(),
          const SizedBox(height: 24),
          const ControlButtons(),
        ],
      ),
    );
  }

  void _setIndex(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    // Read settings here so the widget rebuilds when userName changes.
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(settings),
          const SavedPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: _setIndex,
      ),
    );
  }
}
