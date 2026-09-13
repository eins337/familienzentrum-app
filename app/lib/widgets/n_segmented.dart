import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// v2 SegmentedControl — `soft` track, selected option shown as a white
/// pill with a soft shadow, animated per the README's tab-pill transition.
class NSegmented<T> extends StatelessWidget {
  const NSegmented({super.key, required this.value, required this.options, required this.onChanged, this.expand = false});

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final (optValue, label) in options) {
      final selected = optValue == value;
      final opt = GestureDetector(
        onTap: () => onChanged(optValue),
        child: AnimatedContainer(
          duration: AppMotion.tabPill,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.buttonSm),
            boxShadow: selected ? AppShadows.card : null,
          ),
          child: Text(
            label,
            style: AppText.outfit(size: 12.5, weight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.ink2),
          ),
        ),
      );
      children.add(expand ? Expanded(child: opt) : opt);
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.buttonSm + 3),
      ),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: children),
    );
  }
}
