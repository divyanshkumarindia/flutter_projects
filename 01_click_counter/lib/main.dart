import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The entry point of the application.
void main() => runApp(const MyApp());

/// Manages the state of the counter.
///
/// This provider handles loading, saving, incrementing, and resetting the
/// counter value, persisting it across app sessions using [SharedPreferences].
class CounterProvider extends ChangeNotifier {
  static const _prefsKey = 'counter_value';
  int _count = 0;
  int get count => _count;

  CounterProvider() {
    _loadFromPrefs();
  }

  /// Loads the counter value from shared preferences.
  ///
  /// If no value is found, it defaults to 0.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_prefsKey) ?? 0;
    notifyListeners();
  }

  /// Saves the current counter value to shared preferences.
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _count);
  }

  void increment() {
    _count++;
    _saveToPrefs();
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Reset the counter to zero and persist the change.
  void reset() {
    _count = 0;
    _saveToPrefs();
    notifyListeners();
  }
  // reset() updates the provider's internal value and persists it.
  // notifyListeners() causes widgets that watch the provider (your UI)
  // to rebuild and show the new value.

  // Because _saveToPrefs() stores the value in SharedPreferences,
  // the zeroed value is preserved across app reloads.
  // ---------------------------------------------------------------
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
        theme: ThemeData(primarySwatch: Colors.blue),
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
            
            // Counter display
            const SizedBox(height: 24),
            Text('👍 ${counter.count}', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 24),

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
                foregroundColor: Colors.black,
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Provider.of<CounterProvider>(context, listen: false).reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
