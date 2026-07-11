import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;

  final String? label;
  final String? hint;

  final TextInputType keyboardType;
  final bool isPassword;
  final bool isOtp;
  final int maxLength;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isOtp = false,
    this.maxLength = 50,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: isPassword,
      maxLength: isOtp ? 1 : maxLength,
      textAlign: isOtp ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: isOtp ? 20 : 16,
        fontWeight: isOtp ? FontWeight.bold : FontWeight.normal,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
