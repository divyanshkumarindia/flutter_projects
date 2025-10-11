import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const PremiumBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = [Icons.home, Icons.bookmark, Icons.settings];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgStart = isDark ? Colors.grey.shade900 : Colors.white;
    final bgEnd = isDark ? Colors.grey.shade800 : Colors.grey.shade50;
    final inactiveColor = isDark ? Colors.grey.shade400 : Colors.grey;

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
              final active = currentIndex == i;
              final iconData = items[i];

              return SizedBox(
                width: itemWidth,
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onTap(i),
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
