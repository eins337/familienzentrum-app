import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NCardElevation { none, sm, md, lg }

/// v2 Card — white surface, 20px radius, `cardBorder` hairline, optional
/// colored 4px left rail (used for group-colored / pinned / status cards).
class NCard extends StatefulWidget {
  const NCard({
    super.key,
    required this.child,
    this.elevation = NCardElevation.sm,
    this.padding = const EdgeInsets.all(AppSpace.cardPadding),
    this.borderColor,
    this.background = AppColors.surface,
    this.onTap,
    this.row = false,
  });

  final Widget child;
  final NCardElevation elevation;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color background;
  final VoidCallback? onTap;
  final bool row;

  @override
  State<NCard> createState() => _NCardState();
}

class _NCardState extends State<NCard> {
  bool _pressed = false;

  List<BoxShadow>? get _shadow => switch (widget.elevation) {
        NCardElevation.none => null,
        NCardElevation.sm => AppShadows.card,
        NCardElevation.md => AppShadows.cardElevated,
        NCardElevation.lg => AppShadows.cardElevated,
      };

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: _shadow,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: widget.borderColor == null
          ? widget.child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, margin: const EdgeInsets.only(right: 11), decoration: BoxDecoration(color: widget.borderColor, borderRadius: BorderRadius.circular(2))),
                Expanded(child: widget.child),
              ],
            ),
    );

    if (widget.onTap == null) return content;
    return AnimatedScale(
      scale: _pressed ? AppMotion.cardPressScale : 1,
      duration: AppMotion.press,
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}

/// `.card-kicker` — small uppercase accent label used inside cards.
class NCardKicker extends StatelessWidget {
  const NCardKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppText.sectionLabel(color: AppColors.primary));
  }
}
