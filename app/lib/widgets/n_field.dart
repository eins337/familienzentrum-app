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
        Text(label, style: AppText.nunito(size: 12, weight: FontWeight.w600, color: AppColors.ink2)),
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
      cursorColor: AppColors.primary,
      style: AppText.nunito(size: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.nunito(size: 14, color: AppColors.mutedAlt),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        isDense: true,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
