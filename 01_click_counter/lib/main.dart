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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [_buildHomeTab(), const SavedPage(), const SettingsPage()];
  }

  Widget _buildHomeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Hello Divyansh!',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 24),
          CounterDisplay(),
          SizedBox(height: 24),
          ControlButtons(),
        ],
      ),
    );
  }

  void _setIndex(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: _setIndex,
      ),
    );
  }
}
