import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'country_code_item.dart';

class CountryCodePicker extends StatelessWidget {
  final RxString selectedCode;
  final List<CountryCodeItem> items;
  final ValueChanged<String>? onChanged;

  const CountryCodePicker({
    super.key,
    required this.selectedCode,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => DropdownButton<String>(
        value: selectedCode.value,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item.code,
            child: Text('${item.code} ${item.flag}'),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            selectedCode.value = value;
            onChanged?.call(value);
          }
        },
      ),
    );
  }
}
