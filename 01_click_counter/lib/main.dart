import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
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
              'Hello Divyansh!',
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
            // Counter display and controls (refactored below)
            const SizedBox(height: 24),
            CounterDisplay(),
            const SizedBox(height: 24),
            ControlButtons(),
            // ---------------------------------------------------------------

            // refactored widgets placed above
            // ---------------------------------------------------------------
          ],
        ),
      ),
    );
  }
}

// CounterDisplay: shows the thumbs-up emoji bouncing on increment (number does not animate)
class CounterDisplay extends StatefulWidget {
  const CounterDisplay({super.key});
  @override
  State<CounterDisplay> createState() => _CounterDisplayState();
}

class _CounterDisplayState extends State<CounterDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;
  // Initialize animation controller and listen to provider changes
  // This will allow us to trigger the bounce animation when the counter changes

  @override
  void initState() {
    super.initState();
    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Bounce up by 15% of the height
    _offsetAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    // then back down (not needed, just reverse the same animation)
    // tween means to make a transition between two values (begin and end)

    // Listen to provider changes and trigger bounce when count changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CounterProvider>(context, listen: false);
      provider.addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    // Play bounce: up then back
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  void dispose() {
    Provider.of<CounterProvider>(
      context,
      listen: false,
    ).removeListener(_onProviderChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CounterProvider>().count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated thumbs-up emoji only on increment --------------------------
        SlideTransition(
          position: _offsetAnim,
          child: const Text('👍', style: TextStyle(fontSize: 32)),
        ),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(fontSize: 32)),
      ], // --------------------------------------------------------------------
    );
  }
}

// ControlButtons: Increase and Reset buttons with haptics and reset confirmation + snackbar
class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CounterProvider>(context, listen: false);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            // Haptic feedback is used to provide tactile feedback to the user
            // like a vibration when they press the button
            // selectionClick is a light feedback
            // mediumImpact is a stronger feedback (used in reset button below)
            provider.increment();
          },
          child: const Text('Increase Number'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            // mediumImpact is a stronger feedback
            final confirmed = await showDialog<bool>(
              // This dialog will ask the user for confirmation before resetting.
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
              // Ensure the widget is still mounted before using the context
              if (!context.mounted) return;
              provider.reset();

              // Show snackbar confirmation
              // like a toast message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Counter reset to zero')),
              );
            }
          },
          child: const Text('Reset'), // it's the text for the reset button.
          // here can add an icon if needed.
        ),
      ],
    );
  }
}
