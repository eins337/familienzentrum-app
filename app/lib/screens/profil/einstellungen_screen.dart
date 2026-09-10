import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_tag.dart';

class EinstellungenScreen extends ConsumerWidget {
  const EinstellungenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final family = ref.watch(familyProvider).valueOrNull;
    if (profile == null) return const Scaffold(body: SizedBox());

    Future<void> setNotif(String key, bool value) async {
      final next = Map<String, dynamic>.from(profile.notificationSettings)..[key] = value;
      await ref.read(authServiceProvider).updateNotificationSettings(profile.id, next);
    }

    return Scaffold(
      appBar: NHeader(title: 'Einstellungen', subtitle: family?.name ?? profile.displayName, showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker('Mitteilungen'),
                _Toggle(label: 'Beiträge der Kita', value: profile.notificationSettings['posts'] as bool? ?? true, onChanged: (v) => setNotif('posts', v)),
                _Toggle(label: 'Elternchat', value: profile.notificationSettings['chat'] as bool? ?? true, onChanged: (v) => setNotif('chat', v)),
                _Toggle(label: 'Spielanfragen', value: profile.notificationSettings['playdates'] as bool? ?? true, onChanged: (v) => setNotif('playdates', v)),
                _Toggle(label: 'Nur zwischen 7 und 20 Uhr', value: profile.notificationSettings['quietHours'] as bool? ?? false, onChanged: (v) => setNotif('quietHours', v)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker('Privatsphäre'),
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Mein Kontakt im Elternchat', style: TextStyle(fontSize: 13, color: AppColors.text))),
                      const NTag('Sichtbar', variant: NTagVariant.accent),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Row(
                    children: [
                      Expanded(child: Text('Spielanfragen empfangen', style: TextStyle(fontSize: 13, color: AppColors.text))),
                      NTag('Nur eigene Gruppe', variant: NTagVariant.accent),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Row(
                    children: [
                      Expanded(child: Text('Fotofreigabe', style: TextStyle(fontSize: 13, color: AppColors.text))),
                      NTag('Nur App', variant: NTagVariant.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker('Konto'),
                const SizedBox(height: 6),
                Text(profile.email, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                if (family != null) Text(family.name, style: const TextStyle(fontSize: 11.5, color: AppColors.neutral500)),
                const Divider(height: 20),
                NButton(label: 'Sprache: Deutsch', variant: NButtonVariant.ghost, small: true, onPressed: () {}),
                NButton(label: 'Datenschutz & Nutzungsbedingungen', variant: NButtonVariant.ghost, small: true, onPressed: () {}),
                NButton(
                  label: 'Abmelden',
                  variant: NButtonVariant.ghost,
                  small: true,
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500));
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text))),
          InkWell(onTap: () => onChanged(!value), child: NTag(value ? 'An' : 'Aus', variant: value ? NTagVariant.accent : NTagVariant.neutral)),
        ],
      ),
    );
  }
}
