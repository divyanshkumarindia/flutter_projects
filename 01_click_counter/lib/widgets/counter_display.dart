import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';

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
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));

    final y = ist.year.toString().padLeft(4, '0');
    final m = ist.month.toString().padLeft(2, '0');
    final d = ist.day.toString().padLeft(2, '0');
    final h = ist.hour.toString().padLeft(2, '0');
    final min = ist.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min IST';
  }
}
