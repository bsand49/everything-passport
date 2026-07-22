import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/utils/date_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('DateFormatter', () {
    test('formatDate returns formatted string for valid date', () {
      final date = DateTime(2023, 10, 27);
      // Default locale might vary, but yMd usually produces M/d/y or d/M/y
      // We can use a specific locale for testing if needed, or just check it's not empty
      final formatted = DateFormatter.formatDate(date);
      expect(formatted, isNotEmpty);
      expect(formatted, contains('2023'));
      expect(formatted, contains('10'));
      expect(formatted, contains('27'));
    });

    test('formatDate returns empty string for null date', () {
      expect(DateFormatter.formatDate(null), '');
    });

    test('formatDate respects locale', () {
      final date = DateTime(2023, 10, 27);
      // US locale: 10/27/2023
      expect(DateFormatter.formatDate(date, locale: 'en_US'), '10/27/2023');
      // Some locales use dots or dashes, e.g. de_DE: 27.10.2023
      expect(DateFormatter.formatDate(date, locale: 'de_DE'), '27.10.2023');
    });
  });
}
