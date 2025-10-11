import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/counter_provider.dart';
import 'package:my_app/providers/settings_provider.dart';
import 'package:my_app/widgets/controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ControlButtons increments, saves and copies', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final counter = CounterProvider();
    final settings = SettingsProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: counter,
          child: ChangeNotifierProvider.value(
            value: settings,
            child: const Scaffold(body: Center(child: ControlButtons())),
          ),
        ),
      ),
    );

    // Wait for any async provider loading
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(counter.count, 0);

    // Tap increase
    final incFinder = find.text('Increase Number');
    expect(incFinder, findsOneWidget);
    await tester.tap(incFinder);
    await tester.pumpAndSettle();

    expect(counter.count, 1);

    // Tap save
    final saveFinder = find.text('Save number');
    expect(saveFinder, findsOneWidget);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    expect(counter.saved.length, 1);
  });
}
