import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../theme/tokens.dart';
import '../utils/time_format.dart';
import 'n_button.dart';
import 'n_card.dart';

/// The date-chip event row — "Nov 11 · Laternenfest · Zusagen".
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event});
  final KitaEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(profileProvider).valueOrNull?.id;
    final rsvped = myId != null && event.rsvpUids.contains(myId);

    return NCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Text(monthNameShort(event.eventDate.month).toUpperCase(),
                    style: const TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.primary)),
                Text('${event.eventDate.day}',
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 23, color: AppColors.ink)),
              ],
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                Text(
                  [event.timeLabel, event.location, event.groupId == null ? 'alle Gruppen' : null].whereType<String>().join(' · '),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          NButton(
            label: rsvped ? 'Dabei ✓' : 'Zusagen',
            variant: rsvped ? NButtonVariant.success : NButtonVariant.primary,
            small: true,
            onPressed: () => ref.read(kitaServiceProvider).toggleRsvp(event.id),
          ),
        ],
      ),
    );
  }
}
