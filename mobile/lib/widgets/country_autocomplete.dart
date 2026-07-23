import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../models/country.dart';

class CountryAutocomplete extends StatelessWidget {
  final List<Country> countries;
  final Country? initialValue;
  final ValueChanged<Country?> onSelected;
  final String labelText;
  final IconData prefixIcon;

  const CountryAutocomplete({
    super.key,
    required this.countries,
    this.initialValue,
    required this.onSelected,
    this.labelText = 'Nationality (Optional)',
    this.prefixIcon = Icons.flag,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Country>(
      displayStringForOption: (Country option) => option.name,
      initialValue: TextEditingValue(text: initialValue?.name ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final sortedCountries = List<Country>.from(countries)
          ..sort((a, b) => a.name.compareTo(b.name));

        if (textEditingValue.text.isEmpty) {
          return sortedCountries;
        }
        return sortedCountries.where((Country country) {
          final query = textEditingValue.text.toLowerCase();
          return country.name.toLowerCase().contains(query) ||
              country.searchKeywords
                  .any((k) => k.toLowerCase().contains(query));
        });
      },
      onSelected: (Country selection) {
        onSelected(selection);
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              width: 300,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Country option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelectedOption(option),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CountryFlag.fromCountryCode(
                            option.id,
                            theme: const ImageTheme(
                              width: 24,
                              height: 24,
                              shape: Circle(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option.name)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            final selectedCountry = countries
                .where(
                  (c) => c.name.toLowerCase() == controller.text.toLowerCase(),
                )
                .firstOrNull;

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: labelText,
                border: const OutlineInputBorder(),
                prefixIcon: selectedCountry != null
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CountryFlag.fromCountryCode(
                          selectedCountry.id,
                          theme: const ImageTheme(
                            width: 24,
                            height: 24,
                            shape: Circle(),
                          ),
                        ),
                      )
                    : Icon(prefixIcon),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onSelected(null);
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
