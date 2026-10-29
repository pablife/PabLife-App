import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/themes/app_colors.dart';

class AppTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool expands;
  final TextCapitalization textCapitalization;

  const AppTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.controller,
    this.initialValue,
    this.inputFormatters,
    this.suffixIcon,
    this.maxLines,
    this.minLines,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.expands = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      maxLines: expands ? null : (maxLines ?? 1),
      minLines: minLines,
      expands: expands,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? Colors.black : Colors.black.withAlpha(100),
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorStyle: const TextStyle(color: AppColors.error),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: suffixIcon,
        ),
        labelStyle: TextStyle(
          fontSize: 16,
          color: Colors.black.withAlpha(enabled ? 143 : 80),
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          fontSize: 16,
          color: Colors.black.withAlpha(enabled ? 143 : 80),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: enabled ? AppColors.white : AppColors.white.withAlpha(150),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
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
    );
  }
}
