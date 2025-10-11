import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';

// Local copy of IST formatter to avoid circular imports.
String formatToIst(DateTime dt) {
  final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
  final y = ist.year.toString().padLeft(4, '0');
  final m = ist.month.toString().padLeft(2, '0');
  final d = ist.day.toString().padLeft(2, '0');
  final h = ist.hour.toString().padLeft(2, '0');
  final min = ist.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min IST';
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

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
    );
  }
}
