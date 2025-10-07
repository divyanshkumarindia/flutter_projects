import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MyApp());

class CounterProvider extends ChangeNotifier {
  static const _prefsKey = 'counter_value';
  static const _prefsUpdatedKey = 'counter_last_updated';
  static const _prefsSavedKey = 'counter_saved_list';
  // Keys for SharedPreferences, to store the counter value and last updated timestamp.
  int _count = 0;
  DateTime? _lastUpdated;
  bool _shouldAnimate = false;
  final List<int> _saved = [];
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
    // load saved list
    final savedList = prefs.getStringList(_prefsSavedKey) ?? <String>[];
    _saved.clear();
    for (final s in savedList) {
      final v = int.tryParse(s);
      if (v != null) _saved.add(v);
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
    // save list as strings
    await prefs.setStringList(
      _prefsSavedKey,
      _saved.map((e) => e.toString()).toList(),
    );
  }

  /// Save the current counter value into the saved list (deduplicated at top).
  void saveCurrent() {
    // avoid duplicates of the same value in sequence
    if (_saved.isEmpty || _saved.first != _count) {
      _saved.insert(0, _count);
      // keep list reasonably small for performance
      if (_saved.length > 200) _saved.removeRange(200, _saved.length);
      _saveToPrefs();
      notifyListeners();
    }
  }

  List<int> get saved => List.unmodifiable(_saved);

  void deleteSavedAt(int index) {
    if (index < 0 || index >= _saved.length) return;
    _saved.removeAt(index);
    _saveToPrefs();
    notifyListeners();
  }

  /// Clear all saved entries
  void clearSaved() {
    if (_saved.isEmpty) return;
    _saved.clear();
    _saveToPrefs();
    notifyListeners();
  }

  /// Restore the saved value into current counter
  void restoreSavedAt(int index) {
    if (index < 0 || index >= _saved.length) return;
    final v = _saved[index];
    restore(v);
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

// The previous stateless MyHomePage has been replaced by a stateful
// implementation below that supports tabbed navigation (IndexedStack).

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Pages: Home (we'll build on the fly), Saved, Settings
    _pages.add(_buildHomeTab());
    _pages.add(const _SavedPage());
    _pages.add(const _SettingsPage());
  }

  Widget _buildHomeTab() {
    return Center(
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
    );
  }

  void _setIndex(int i) {
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: _setIndex,
      ),
    );
  }
}

// (Removed old placeholder) - real SavedPage is implemented below.

// Simple placeholder Settings page (layout only)
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.settings, size: 72, color: Colors.grey),
              SizedBox(height: 12),
              Text('Settings (placeholder)'),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple placeholder Settings page (layout only)
class _SavedPage extends StatelessWidget {
  const _SavedPage();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CounterProvider>(context);
    final items = provider.saved;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and optional Delete all button aligned right
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Saved counters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    IconButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete all saved values'),
                            content: const Text(
                              'Are you sure you want to delete all saved counters? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete all'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          if (!context.mounted) return;
                          provider.clearSaved();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All saved values deleted'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_forever_outlined),
                      tooltip: 'Delete all',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No saved counters yet. Save values from Home.',
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final v = items[index];
                      return ListTile(
                        title: Text(
                          'Value: $v',
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle: Text('Tap to restore'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete saved value'),
                                content: Text('Delete saved value $v?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              if (!context.mounted) return;
                              provider.deleteSavedAt(index);
                            }
                          },
                        ),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Restore saved value'),
                              content: Text('Restore counter to $v?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Restore'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            if (!context.mounted) return;
                            provider.restoreSavedAt(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Restored $v')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      // No FAB here; use the Save button on Home and Delete All in header above.
    );
  }
}

// Premium-looking bottom nav with animated active icon
class _PremiumBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({required this.currentIndex, required this.onTap});

  @override
  State<_PremiumBottomNav> createState() => _PremiumBottomNavState();
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

  @override
  void initState() {
    super.initState();
    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CounterProvider>(context, listen: false);
      provider.addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    final provider = Provider.of<CounterProvider>(context, listen: false);
    if (provider.shouldAnimate) {
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
    final utcMillis = dt.toUtc().millisecondsSinceEpoch;
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

class _PremiumBottomNavState extends State<_PremiumBottomNav>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final items = [Icons.home, Icons.bookmark, Icons.settings];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final active = widget.currentIndex == i;
              return GestureDetector(
                onTap: () => widget.onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.all(active ? 12 : 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? Colors.blue : Colors.grey.shade100,
                  ),
                  child: Icon(
                    items[i],
                    color: active ? Colors.white : Colors.grey,
                    size: active ? 28 : 24,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
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

        // Copy, Save, and Share buttons ----------------------------------------------
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
                // Save current count to saved list
                provider.saveCurrent();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved current value')),
                );
              },
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Save number'),
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
