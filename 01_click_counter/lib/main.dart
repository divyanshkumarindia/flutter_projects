import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// The difference between provider and setState is that, provider allows state to be shared across multiple widgets and screens,
// while setState is limited to the widget it is called in. 
// It's a more scalable way to manage state in larger apps.

// Entry point — start the app with MyApp as root.
void main() => runApp(const MyApp());
// The app starts here. 
// runApp() tells Flutter to render the widget tree starting with MyApp.

// CounterProvider for state management.
// where the count lives and how it's updated
class CounterProvider extends ChangeNotifier { // -----------------
  int _count = 0;
  int get count => _count;
  // _count is a private integer (starts at 0).
  // get count => _count; gives read access to the value.

  void increment() {
    _count++;
    // changing the state
    notifyListeners(); // ---------------------
  // Why ChangeNotifier and notifyListeners? // <-----
  // ChangeNotifier is a simple way to notify any listening widgets that the state changed.
  // notifyListeners() tells Provider: "Hey, something changed — rebuild listening widgets."
  }
}

// Root application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // we used super.key to pass the key to the superclass constructor.
  // key is an optional parameter that helps Flutter identify widgets uniquely in the widget tree.

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // ------------
      // This makes CounterProvider available to all widgets below it in the widget tree.
      create: (_) => CounterProvider(), // ---------
      // Provider is a state management solution for Flutter.
      child: MaterialApp( // ---------------------
        // This wraps your MaterialApp with a Provider,
        // that makes CounterProvider available to the widget tree.
        debugShowCheckedModeBanner: false,
        title: 'Flutter Basic App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MyHomePage(),
      ),
    );
  }
}

// Home screen.
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {

    final counter = context.watch<CounterProvider>();
    //This line tells Flutter: “I want to read CounterProvider here and rebuild when it changes.”

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
            const SizedBox(height: 24),
            Text(
              '👍 ${counter.count}',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Provider.of<CounterProvider>(context, listen: false).increment(),
              // This finds the CounterProvider instance (listen: false means "don't subscribe here") and calls increment().
              // Inside increment():
              // -- _count++ increases the stored number.
              // -- notifyListeners() tells Provider to rebuild any widgets that are watching this provider.
              child: const Text('Increase Number'),
            ),
          ],
        ),
      ),
    );
  }
}

  // Tiny glossary for terms used:
  // Widget: a UI building block (buttons, text, layout containers).
  // StatelessWidget: a widget that doesn't store state.
  // StatefulWidget + State: a widget that stores mutable state inside a State object.
  // Provider: a package that makes state available to widgets and notifies listeners when it changes.
  // ChangeNotifier: an object that can notify listeners about changes.
  // notifyListeners(): call this after changing state so widgets rebuild.
  // context.watch<T>(): read and subscribe to a Provider<T>.
  // Provider.of<T>(context, listen: false): read Provider<T> without subscribing.

  // Quick notes / improvements you might consider:
  // Persist the counter (e.g., SharedPreferences) if you want it across app restarts.
  // Add persistence so the count is stored across app launches.
  // For larger state needs, consider more structured patterns (Riverpod, Bloc) — but Provider is fine for this use case.
  // Explore using Riverpod or Bloc for more complex state management.

// That's it! A simple click counter app using Provider for state management.