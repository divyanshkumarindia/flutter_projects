import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/counter_provider.dart';
import 'package:my_app/screens/saved.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SavedPage shows saved entries and allows delete all', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final counter = CounterProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    // Pre-populate a saved entry
  counter.increment();
  await counter.saveCurrent(label: 'a');

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: counter,
          child: const SavedPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Saved counters'), findsOneWidget);
    expect(find.textContaining('a'), findsOneWidget);

    // Tap delete all
    final deleteButton = find.byTooltip('Delete all');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Delete all saved values'), findsOneWidget);
    final confirm = find.text('Delete all');
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(counter.saved.length, 0);
  });
}
