import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A confirmation dialog for destructive admin actions (delete family,
/// delete account, …) — several of these called the delete method
/// directly from the icon's onPressed with no confirmation at all.
Future<bool> confirmDestructive(BuildContext context, {required String title, required String message, String confirmLabel = 'Löschen'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: AppColors.ink)),
      content: Text(message, style: const TextStyle(color: AppColors.ink2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel, style: const TextStyle(color: AppColors.error))),
      ],
    ),
  );
  return result ?? false;
}

/// Runs a quick one-shot mutation (like/RSVP/poll-vote toggles) and shows
/// an error SnackBar if it fails — several of these buttons across the app
/// were calling the service method directly with no error handling at
/// all, so any failure (network blip, RLS denial) just looked like the
/// button had no function.
Future<void> runOrShowError(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
  }
}

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
