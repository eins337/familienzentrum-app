import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Nocturne `.field` + `.input` — a labeled text field matching the
/// prototype's form styling (surface background, divider border, 8px radius).
class NField extends StatelessWidget {
  const NField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.text.withValues(alpha: 0.7))),
        const SizedBox(height: 5),
        NInput(
          controller: controller,
          hintText: hintText,
          obscureText: obscureText,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          autofocus: autofocus,
        ),
      ],
    );
  }
}

/// The bare `.input` box, usable without a label (e.g. search fields).
class NInput extends StatelessWidget {
  const NInput({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.prefixIcon,
  });

  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      autofocus: autofocus,
      cursorColor: AppColors.accent,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.neutral600),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
