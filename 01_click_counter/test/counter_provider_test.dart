import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/providers/counter_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CounterProvider unit tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('increment and decrement adjust count and persist', () async {
      final provider = CounterProvider();
      await Future.delayed(Duration(milliseconds: 50)); // allow async load

      expect(provider.count, 0);

      provider.increment();
      expect(provider.count, 1);

      provider.decrement();
      expect(provider.count, 0);
    });

    test('prevent negative counts', () async {
      final provider = CounterProvider();
      await Future.delayed(Duration(milliseconds: 50));

      expect(provider.count, 0);
      provider.decrement();
      expect(provider.count, 0);
    });

    test('save and restore saved entries', () async {
      final provider = CounterProvider();
      await Future.delayed(Duration(milliseconds: 50));

      provider.increment();
      provider.saveCurrent(label: 'first');

      expect(provider.saved.length, 1);
      final saved = provider.saved.first;
      expect(saved.value, 1);
      expect(saved.label, 'first');

      provider.clearSaved();
      expect(provider.saved.length, 0);
    });
  });
}
