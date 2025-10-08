import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

// Helper: format DateTime to IST string
String formatToIst(DateTime dt) {
  final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
  final y = ist.year.toString().padLeft(4, '0');
  final m = ist.month.toString().padLeft(2, '0');
  final d = ist.day.toString().padLeft(2, '0');
  final h = ist.hour.toString().padLeft(2, '0');
  final min = ist.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min IST';
}

class CounterProvider extends ChangeNotifier {
  static const _prefsKey = 'counter_value';
  static const _prefsUpdatedKey = 'counter_last_updated';
  static const _prefsSavedKey = 'counter_saved_list';
  // Keys for SharedPreferences, to store the counter value and last updated timestamp.
  int _count = 0;
  DateTime? _lastUpdated;
  bool _shouldAnimate = false;
  final List<SavedEntry> _saved = [];
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
    // load saved list (support legacy string ints and new JSON objects)
    final savedList = prefs.getStringList(_prefsSavedKey) ?? <String>[];
    _saved.clear();
    for (final s in savedList) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        _saved.add(SavedEntry.fromJson(map));
      } catch (_) {
        // fallback to legacy int string
        final v = int.tryParse(s);
        if (v != null) {
          _saved.add(SavedEntry(value: v, savedAt: null, label: null));
        }
      }
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
    // save list as json strings
    await prefs.setStringList(
      _prefsSavedKey,
      _saved.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Save the current counter value into the saved list (deduplicated at top).
  void saveCurrent({String? label}) {
    // avoid duplicates of the same value in sequence
    if (_saved.isEmpty || _saved.first.value != _count) {
      _saved.insert(
        0,
        SavedEntry(value: _count, savedAt: DateTime.now(), label: label),
      );
      // keep list reasonably small for performance
      if (_saved.length > 200) _saved.removeRange(200, _saved.length);
      _saveToPrefs();
      notifyListeners();
    }
  }

  List<SavedEntry> get saved => List.unmodifiable(_saved);

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
    final entry = _saved[index];
    restore(entry.value, updatedAt: entry.savedAt);
  }

  /// Rename/edit a saved entry's label
  void renameSavedAt(int index, String? label) {
    if (index < 0 || index >= _saved.length) return;
    final e = _saved[index];
    _saved[index] = e.copyWith(label: label);
    _saveToPrefs();
    notifyListeners();
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

/// A saved entry with value, optional savedAt timestamp, and optional label.
class SavedEntry {
  final int value;
  final DateTime? savedAt;
  final String? label;

  SavedEntry({required this.value, this.savedAt, this.label});

  SavedEntry copyWith({int? value, DateTime? savedAt, String? label}) {
    return SavedEntry(
      value: value ?? this.value,
      savedAt: savedAt ?? this.savedAt,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'savedAt': savedAt?.millisecondsSinceEpoch,
    'label': label,
  };

  static SavedEntry fromJson(Map<String, dynamic> m) {
    final savedAtMillis = m['savedAt'] as int?;
    return SavedEntry(
      value: (m['value'] as num).toInt(),
      savedAt: savedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(savedAtMillis)
          : null,
      label: m['label'] as String?,
    );
  }

  @override
  String toString() =>
      'SavedEntry(value: $value, savedAt: $savedAt, label: $label)';
}

//-----------------------------------------------------------------------------
// SettingsProvider holds user preferences persisted to SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  static const _prefsDarkKey = 'settings_dark_mode';
  static const _prefsHapticsKey = 'settings_haptics';
  static const _prefsConfirmResetKey = 'settings_confirm_reset';
  // Keys for SharedPreferences, to store user settings.

  // bool is used for true/false settings
  bool _isDark = false; // default to light mode
  bool _hapticsEnabled = true; // default to haptics on
  bool _confirmReset = true; // default to confirm on reset

  bool get isDarkMode =>
      _isDark; // true if dark mode is enabled, and if false then it's light mode, like here it's false.
  bool get hapticsEnabled => _hapticsEnabled; // true if haptics are enabled
  bool get confirmReset =>
      _confirmReset; // true if confirmation is required on reset

  SettingsProvider() {
    _load();
  }

  // Load settings from SharedPreferences
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefsDarkKey) ?? false;
    _hapticsEnabled = prefs.getBool(_prefsHapticsKey) ?? true;
    _confirmReset = prefs.getBool(_prefsConfirmResetKey) ?? true;
    notifyListeners();
  }

  // Save settings to SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsDarkKey, _isDark);
    await prefs.setBool(_prefsHapticsKey, _hapticsEnabled);
    await prefs.setBool(_prefsConfirmResetKey, _confirmReset);
  }

  // Setters that update the value, save to prefs, and notify listeners
  set isDarkMode(bool v) {
    if (_isDark == v) return;
    _isDark = v;
    _save();
    notifyListeners();
  }

  // Setter for hapticsEnabled
  set hapticsEnabled(bool v) {
    if (_hapticsEnabled == v) return;
    _hapticsEnabled = v;
    _save();
    notifyListeners();
  }

  // Setter for confirmReset
  set confirmReset(bool v) {
    if (_confirmReset == v) return;
    _confirmReset = v;
    _save();
    notifyListeners();
  }
}

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
          title: 'Flutter Basic App',
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
      appBar: AppBar(
        // AppBar with icon and title
        title: Row(
          children: const [
            Icon(Icons.settings, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
      ),
      body: SafeArea(
        // here safe area is used to avoid notches and system UI overlaps.
        // In this widget, we will use a Padding widget to give some space around the content.
        // And inside, we will use a Consumer to listen to SettingsProvider.
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) => ListView(
              // ListView for scrollable content
              // ListView allows vertical scrolling if content overflows.
              children: [
                const SizedBox(height: 8),
                SwitchListTile(
                  // Switch for dark mode
                  // switchlisttile is a widget that provides a switch with a title and subtitle.
                  title: const Text('Dark theme'),
                  subtitle: const Text('Use dark mode for the app'),
                  value: settings.isDarkMode,
                  onChanged: (v) => settings.isDarkMode = v,
                ),
                const Divider(),
                SwitchListTile(
                  // Switch for haptics
                  title: const Text('Haptics'),
                  subtitle: const Text('Enable vibration feedback'),
                  value: settings.hapticsEnabled,
                  onChanged: (v) => settings.hapticsEnabled = v,
                ),
                const Divider(),
                SwitchListTile(
                  // Switch for confirmation on reset
                  title: const Text('Confirm on reset'),
                  subtitle: const Text('Ask for confirmation before resetting'),
                  value: settings.confirmReset,
                  onChanged: (v) => settings.confirmReset = v,
                ),
                const SizedBox(height: 16),
                Card(
                  // About card with app info
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click Counter — a tiny Flutter app to track and save counts.',
                        ),
                        SizedBox(height: 6),
                        Text('Developer: Divyansh Singh'),
                        SizedBox(height: 6),
                        Text(
                          'Made with ❤️ — lightweight, simple, and persistent.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      showAboutDialog(
                        // show about dialog with app info
                        // dialog shows app name, version, and developer info.
                        context: context,
                        applicationName: 'Click Counter',
                        applicationVersion: '1.0.0',
                        children: const [
                          Text('Simple counter app by Divyansh Singh.'),
                        ],
                      );
                    },
                    child: const Text('App info'),
                  ),
                ),
              ],
            ),
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
              // Header with icon, title and saved-count
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark, size: 28, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved counters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${items.length} saved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
                      final entry = items[index];
                      final titleText = entry.label?.isNotEmpty == true
                          ? '${entry.label} — ${entry.value}'
                          : 'Value: ${entry.value}';
                      final subtitle = entry.savedAt != null
                          ? 'Saved: ${formatToIst(entry.savedAt!)}'
                          : 'Saved: N/A';

                      return ListTile(
                        title: Text(
                          titleText,
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle: Text(subtitle),
                        leading: const Icon(Icons.bookmark_outline),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit label',
                              onPressed: () async {
                                final controller = TextEditingController(
                                  text: entry.label ?? '',
                                );
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Edit label'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText: 'Short label',
                                      ),
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
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  if (!context.mounted) return;
                                  provider.renameSavedAt(
                                    index,
                                    controller.text.trim().isEmpty
                                        ? null
                                        : controller.text.trim(),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete saved value'),
                                    content: Text(
                                      'Delete saved value ${entry.value}?',
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
                          ],
                        ),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Restore saved value'),
                              content: Text(
                                'Restore counter to ${entry.value}?',
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
                                  child: const Text('Restore'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            if (!context.mounted) return;
                            provider.restoreSavedAt(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Restored ${entry.value}'),
                              ),
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
    // Convert the provided DateTime to IST (UTC+5:30) deterministically
    // Avoid relying on local system timezone conversions; add the offset to UTC.
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));

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

    // Determine colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgStart = isDark ? Colors.grey.shade900 : Colors.white;
    final bgEnd = isDark ? Colors.grey.shade800 : Colors.grey.shade50;
    final inactiveColor = isDark ? Colors.grey.shade400 : Colors.grey;
    // here the gradient is defined with two colors.

    const double itemWidth = 76.0;
    const double circleSize = 48.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(colors: [bgStart, bgEnd])
                : LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 195, 209, 246),
                      const Color.fromARGB(255, 202, 216, 255),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color.fromARGB(141, 0, 0, 0)
                    : Colors.blue.withAlpha((0.06 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final active = widget.currentIndex == i;
              final iconData = items[i];

              // Each item is a SizedBox with InkWell for tap detection
              // and a TweenAnimationBuilder for smooth scaling and translation.
              // Also
              return SizedBox(
                width: itemWidth,
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => widget.onTap(i),
                    splashColor: Colors.white24,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 1.0,
                        end: active ? 1.12 : 1.0,
                      ),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        final translateY = active ? -6.0 : 0.0;
                        return Transform.translate(
                          offset: Offset(0, translateY),
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.center,
                            child: child,
                          ),
                        );
                      },
                      child: Material(
                        color: active
                            ? Colors.blue
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100),
                        shape: const CircleBorder(),
                        elevation: active ? 6 : 0,
                        child: SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                iconData,
                                color: active ? Colors.white : inactiveColor,
                                size: active ? 28 : 24,
                              ),
                              if (iconData == Icons.bookmark &&
                                  context
                                      .watch<CounterProvider>()
                                      .saved
                                      .isNotEmpty)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${context.watch<CounterProvider>().saved.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    // settings is used to check if haptics are enabled.
    return Column(
      children: [
        // Row with left arrow, main increase button, and right arrow
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left arrow (decrement)
            _RepeatIconButton(
              icon: Icons.arrow_left,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              onTap: () {
                if (settings.hapticsEnabled) HapticFeedback.selectionClick();
                // setting haptics enabled will provide feedback
                // and selectionClick is a light feedback
                provider.decrement(animate: true);
              },
              onHold: () {
                // continuous fast decrement while holding
                provider.decrement(animate: false);
              },
            ),
            const SizedBox(width: 8),
            // Sized box for spacing
            ElevatedButton(
              onPressed: () {
                if (settings.hapticsEnabled) HapticFeedback.selectionClick();
                // single-tap increment should animate
                provider.increment(animate: true);
              },
              child: const Text('Increase Number'),
            ),
            const SizedBox(width: 8),
            // Right arrow (increment)
            _RepeatIconButton(
              icon: Icons.arrow_right,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              onTap: () {
                if (settings.hapticsEnabled) HapticFeedback.selectionClick();
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
                // Fallback: copy to clipboard (no share_plus dependency)
                Clipboard.setData(
                  ClipboardData(text: provider.count.toString()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Count copied for sharing')),
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
            if (settings.hapticsEnabled) HapticFeedback.mediumImpact();
            // If confirmation is enabled show dialog, otherwise proceed
            final confirmed = settings.confirmReset
                ? await showDialog<bool>(
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
                  )
                : true;

            if (confirmed == true) {
              if (!context.mounted) return;
              provider.reset();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Counter reset to zero')),
              );
            }
          },
          child: const Text('Reset'), // it's the text for the reset button.
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
