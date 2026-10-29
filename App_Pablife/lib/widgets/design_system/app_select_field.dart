import 'package:flutter/material.dart';

import '../../shared/themes/app_colors.dart';

class SelectOption {
  final String value;
  final String label;

  const SelectOption({required this.value, required this.label});
}

class AppSelectField<T> extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;
  final T? value;
  final List<SelectOption> items;
  final T? Function(String)? valueFromString;

  const AppSelectField({
    super.key,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.value,
    required this.items,
    this.valueFromString,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          fontSize: 16,
          color: Colors.black.withAlpha(143),
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          fontSize: 16,
          color: Colors.black.withAlpha(143),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.aquaButton, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      dropdownColor: AppColors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      isExpanded: true,
      items: items.map((item) {
        final itemValue = valueFromString != null
            ? valueFromString!(item.value)
            : item.value as T?;
        return DropdownMenuItem<T>(value: itemValue, child: Text(item.label));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
