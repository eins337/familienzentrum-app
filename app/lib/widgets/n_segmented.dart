import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Nocturne `.seg` / `.seg-opt` — a segmented control used for the
/// Eltern/Kita-Team role switcher, info tabs, and radio-style pickers.
class NSegmented<T> extends StatelessWidget {
  const NSegmented({super.key, required this.value, required this.options, required this.onChanged, this.expand = false});

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      final (optValue, label) = options[i];
      final selected = optValue == value;
      final opt = InkWell(
        onTap: () => onChanged(optValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(left: i > 0 ? const BorderSide(color: AppColors.divider) : BorderSide.none),
            boxShadow: selected ? [const BoxShadow(color: AppColors.accent, spreadRadius: 1, blurRadius: 0)] : null,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: selected ? AppColors.accent : AppColors.text),
          ),
        ),
      );
      children.add(expand ? Expanded(child: opt) : opt);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: children),
    );
  }
}
