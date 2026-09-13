import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// v2 Toast — floating pill, `ink` background, white text, the README's
/// `toastIn` motion (translateY 12px → 0, 220ms) and a 2800ms auto-dismiss.
void showNToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => _ToastWidget(message: message),
  );
  overlay.insert(entry);
  Future.delayed(AppMotion.toastDismiss + AppMotion.toastIn, entry.remove);
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({required this.message});
  final String message;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.toastIn);
    _offset = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future.delayed(AppMotion.toastDismiss, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 32,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _offset,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.buttonLg), boxShadow: AppShadows.toast),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: AppText.nunito(size: 13.5, weight: FontWeight.w600, color: AppColors.surface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
