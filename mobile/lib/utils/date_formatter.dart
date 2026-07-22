import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime? date, {String? locale}) {
    if (date == null) return '';
    return DateFormat.yMd(locale).format(date);
  }
}
