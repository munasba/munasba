import 'package:flutter/material.dart';

class FilterOption {
  final String value;
  final String label;
  const FilterOption(this.value, this.label);
}

class FilterChipRow extends StatelessWidget {
  final List<FilterOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterChipRow({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map((o) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(o.label),
                    selected: selected == o.value,
                    onSelected: (_) => onSelected(o.value),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
