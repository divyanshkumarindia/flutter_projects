import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';

class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CounterProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RepeatIconButton(
              icon: Icons.arrow_left,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              onTap: () {
                if (settings.hapticsEnabled) HapticFeedback.selectionClick();
                provider.decrement(animate: true);
              },
              onHold: () {
                provider.decrement(animate: false);
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (settings.hapticsEnabled) HapticFeedback.selectionClick();
                provider.increment(animate: true);
              },
              child: const Text('Increase Number'),
            ),
            const SizedBox(width: 8),
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
                provider.increment(animate: false);
              },
            ),
          ],
        ),

        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
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

        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            if (settings.hapticsEnabled) HapticFeedback.mediumImpact();
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
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

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
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }
}
