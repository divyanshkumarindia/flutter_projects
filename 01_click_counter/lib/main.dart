import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class CounterProvider extends ChangeNotifier {
  static const _prefsKey = 'counter_value';
  int _count = 0;
  int get count => _count;

  CounterProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_prefsKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _count);
  }

  void increment() {
    _count++;
    _saveToPrefs();
    notifyListeners();
  }

  void reset() {
    _count = 0;
    _saveToPrefs();
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Basic App',
        // ---------------------------------------------------------------
        theme: ThemeData(
          primarySwatch: Colors.blue,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            // ------------------------------------------------------------
          ),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              if (kDebugMode) print('Settings button pressed');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Styled text using Google Fonts
            Text(
              'Hello India!',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Counter display with small animation
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '👍 ${counter.count}',
                key: ValueKey<int>(counter.count),
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 24),
            // ---------------------------------------------------------------

            // Increment Button
            ElevatedButton(
              onPressed: () => Provider.of<CounterProvider>(
                context,
                listen: false,
              ).increment(),
              child: const Text('Increase Number'),
            ),

            // Reset Button (ADDED)
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              // -------------------------------------------------------------
              onPressed: () async {
                // we used async as we are going to show a dialog
                // dialog is a future that returns a value when closed
                // like here we are returning true or false based on user action
                final provider = Provider.of<CounterProvider>(
                  context,
                  listen: false,
                ); // Capture provider before awaiting the dialog

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm reset'),
                    content: const Text(
                      'Are you sure you want to reset the counter to zero?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  provider.reset();
                }
              },
              child: const Text('Reset'),
            ),
            // ---------------------------------------------------------------
          ],
        ),
      ),
    );
  }
}
