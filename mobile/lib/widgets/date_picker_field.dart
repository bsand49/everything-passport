import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

class DatePickerField extends StatelessWidget {
  final String labelText;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final Locale? locale;

  const DatePickerField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.locale,
  });

  String get _formattedDate {
    return DateFormatter.formatDate(value, locale: locale?.toString());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(2000),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: locale,
    );
    if (picked != null && picked != value) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(_formattedDate),
      ),
    );
  }
}
