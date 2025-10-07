import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
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
  bool _shouldAnimate = false;
  int get count => _count;
  DateTime? get lastUpdated => _lastUpdated;

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
    }
  }

  void increment({bool animate = true}) {
    _count++;
    _lastUpdated = DateTime.now();
    _shouldAnimate = animate;
    _saveToPrefs();
    notifyListeners();
  }

  void decrement({bool animate = false}) {
    if (_count <= 0) return;
    _count--;
    _lastUpdated = DateTime.now();
    _shouldAnimate = animate;
    _saveToPrefs();
    notifyListeners();
  }

  bool get shouldAnimate => _shouldAnimate;

  void clearAnimateFlag() {
    _shouldAnimate = false;
  }

  void reset() {
    _count = 0;
    _lastUpdated = DateTime.now();
    _saveToPrefs();
    notifyListeners();
  }

  void restore(int value, {DateTime? updatedAt}) {
    _count = value;
    _lastUpdated = updatedAt ?? DateTime.now();
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
    final provider = Provider.of<CounterProvider>(context, listen: false);
    // Only animate for single-tap increments that requested animation
    if (provider.shouldAnimate) {
      // Play bounce: up then back
      _controller.forward().then((_) => _controller.reverse());
      provider.clearAnimateFlag();
    }
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
        // Row with left arrow, main increase button, and right arrow
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left arrow (decrement)
            _RepeatIconButton(
              icon: Icons.arrow_left,
              color: Colors.grey.shade300,
              onTap: () {
                HapticFeedback.selectionClick();
                provider.decrement(animate: true);
              },
              onHold: () {
                // continuous fast decrement while holding
                provider.decrement(animate: false);
              },
            ),
            const SizedBox(width: 8),
            // Sized box for spacing
            // And to control the radius of the button  like to make it more rounded or less rounded.
            // to control radius of the button we can use the shape property of the ElevatedButton.
            // like ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
            ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                // single-tap increment should animate
                provider.increment(animate: true);
              },
              child: const Text('Increase Number'),
            ),
            const SizedBox(width: 8),
            // Right arrow (increment)
            _RepeatIconButton(
              icon: Icons.arrow_right,
              color: Colors.grey.shade300,
              onTap: () {
                HapticFeedback.selectionClick();
                provider.increment(animate: true);
              },
              onHold: () {
                // continuous fast increment while holding
                provider.increment(animate: false);
              },
            ),
          ],
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

/// A small icon button that supports single tap and press-and-hold repeating.
class _RepeatIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onHold;

  const _RepeatIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onHold,
  });

  @override
  State<_RepeatIconButton> createState() => _RepeatIconButtonState();
}

class _RepeatIconButtonState extends State<_RepeatIconButton> {
  Timer? _repeatTimer;
  Timer? _delayTimer;

  void _startRepeat() {
    // small initial delay then repeat quickly
    _delayTimer = Timer(const Duration(milliseconds: 300), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        widget.onHold();
      });
    });
  }

  void _stopRepeat() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    _delayTimer = null;
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _startRepeat(),
      onTapUp: (_) => _stopRepeat(),
      onTapCancel: () => _stopRepeat(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(widget.icon, size: 24),
      ),
    );
  } // This section is used to build the icon button with tap and hold functionality.

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }
}
