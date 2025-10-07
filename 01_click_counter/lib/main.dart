import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// SharePlus is a popular package for sharing content via the platform's share sheet.

void main() => runApp(const MyApp());

class CounterProvider extends ChangeNotifier {
  static const _prefsKey = 'counter_value';
  static const _prefsUpdatedKey = 'counter_last_updated';
  // Keys for SharedPreferences, to store the counter value and last updated timestamp.
  int _count = 0;
  DateTime? _lastUpdated;
  // _lastUpdated can be null initially if never updated, like on first load.
  int get count => _count;
  DateTime? get lastUpdated => _lastUpdated;
  // This lastUpdated getter can return null if never updated.
  // like when the app is first installed and opened.

  CounterProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_prefsKey) ?? 0;
    final millis = prefs.getInt(_prefsUpdatedKey);
    if (millis != null) {
      _lastUpdated = DateTime.fromMillisecondsSinceEpoch(millis);
    }
    // If millis is null, _lastUpdated remains null.
    // Here millis is an integer representing the timestamp in milliseconds since epoch.
    // Epoch is Jan 1, 1970 UTC.
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _count);
    if (_lastUpdated != null) {
      await prefs.setInt(
        _prefsUpdatedKey,
        _lastUpdated!.millisecondsSinceEpoch,
      );
    } // If _lastUpdated is null, we don't save it.
  }

  void increment() {
    _count++;
    _lastUpdated = DateTime.now();
    // Set last updated to current time on increment.
    _saveToPrefs();
    notifyListeners();
  }

  void reset() {
    _count = 0;
    _lastUpdated = DateTime.now();
    _saveToPrefs();
    notifyListeners();
  }

  /// Restore to a given value (used for undo or programmatic restores)
  void restore(int value, {DateTime? updatedAt}) {
    _count = value;
    _lastUpdated = updatedAt ?? DateTime.now();
    // What here we did is that we set last updated to the provided time or now if not provided.
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

            const SizedBox(height: 24),
            CounterDisplay(),
            const SizedBox(height: 24),
            ControlButtons(),
          ],
        ),
      ),
    );
  }
}

class CounterDisplay extends StatefulWidget {
  const CounterDisplay({super.key});
  @override
  State<CounterDisplay> createState() => _CounterDisplayState();
}

class _CounterDisplayState extends State<CounterDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;

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
    final last = context.watch<CounterProvider>().lastUpdated;
    // here last can be null if never updated.
    // Build a compact column: a row with emoji + number, then timestamp centered
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlideTransition(
              position: _offsetAnim,
              child: const Text('👍', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 8),
            Text('$count', style: const TextStyle(fontSize: 32)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          last != null ? 'Updated: ${_formatTimestamp(last)}' : 'Updated: N/A',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _formatTimestamp(DateTime dt) {
    // Convert the provided DateTime to IST (UTC+5:30) and format as
    // YYYY-MM-DD HH:MM. We do not change the original timezone of `dt` but
    // compute the IST equivalent from UTC milliseconds since epoch.
    final utcMillis = dt.toUtc().millisecondsSinceEpoch;
    // IST offset in milliseconds = 5.5 hours
    const istOffsetMillis = 5 * 60 * 60 * 1000 + 30 * 60 * 1000;
    final ist = DateTime.fromMillisecondsSinceEpoch(
      utcMillis + istOffsetMillis,
      isUtc: true,
    ).toLocal();

    final y = ist.year.toString().padLeft(4, '0');
    final m = ist.month.toString().padLeft(2, '0');
    final d = ist.day.toString().padLeft(2, '0');
    final h = ist.hour.toString().padLeft(2, '0');
    final min = ist.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min IST';
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

        // Copy and Share buttons ----------------------------------------------
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Copy count to clipboard
                Clipboard.setData(
                  ClipboardData(text: provider.count.toString()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Count copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Share using platform share sheet (SharePlus)
                SharePlus.instance.share(
                  ShareParams(text: 'Current count: ${provider.count}'),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
        // ----------------------------------------------------------------------

        // Reset button with confirmation dialog and snackbar
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

              // Snackbar confirmation
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
