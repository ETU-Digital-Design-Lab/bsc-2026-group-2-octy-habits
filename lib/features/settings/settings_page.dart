import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/local_notifications_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';

enum SettingsSection { general, theme, reminders }

class SettingsPage extends ConsumerWidget {
  final SettingsSection section;
  const SettingsPage({super.key, this.section = SettingsSection.general});

  Future<void> _savePreference({
    required WidgetRef ref,
    required String uid,
    required String key,
    required bool value,
  }) async {
    await ref.read(firestoreProvider).collection('users').doc(uid).set({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveStringPreference({
    required WidgetRef ref,
    required String uid,
    required String key,
    required String value,
  }) async {
    await ref.read(firestoreProvider).collection('users').doc(uid).set({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveReminderTime({
    required WidgetRef ref,
    required String uid,
    required TimeOfDay time,
  }) async {
    await ref.read(firestoreProvider).collection('users').doc(uid).set({
      'reminderHour': time.hour,
      'reminderMinute': time.minute,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveReminderDays({
    required WidgetRef ref,
    required String uid,
    required List<bool> selected,
  }) async {
    await ref.read(firestoreProvider).collection('users').doc(uid).set({
      'reminderDays': selected,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _syncReminders({
    required bool enabled,
    required TimeOfDay time,
    required List<bool> days,
  }) async {
    final service = LocalNotificationsService.instance;
    await service.requestPermissions();
    await service.syncWeeklyReminder(
      enabled: enabled,
      hour: time.hour,
      minute: time.minute,
      days: days,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.pageGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: authAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (user) {
              if (user == null) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/gate'),
                    child: const Text('Girişe git'),
                  ),
                );
              }

              final profileAsync = ref.watch(userProfileProvider(user.uid));
              return profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
                data: (profile) {
                  final reminders = profile?['remindersEnabled'] != false;
                  final mondayFirst = profile?['mondayFirst'] == true;
                  final hour = (profile?['reminderHour'] ?? 21) as int;
                  final minute = (profile?['reminderMinute'] ?? 0) as int;
                  final rawThemeMode =
                      (profile?['themeMode'] ?? 'dark') as String;
                  final themeMode =
                      {'system', 'dark', 'light'}.contains(rawThemeMode)
                      ? rawThemeMode
                      : 'dark';
                  final time = TimeOfDay(hour: hour, minute: minute);
                  final dynamic daysRaw = profile?['reminderDays'];
                  final reminderDays = (daysRaw is List && daysRaw.length == 7)
                      ? daysRaw.map((e) => e == true).toList()
                      : List<bool>.filled(7, true);
                  final displayName = (profile?['displayName'] as String?)
                      ?.trim();
                  final name = displayName != null && displayName.isNotEmpty
                      ? displayName
                      : 'Octy dostu';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    children: switch (section) {
                      SettingsSection.theme => [
                        _buildThemeGroup(ref, user.uid, themeMode),
                      ],
                      SettingsSection.reminders => [
                        _buildReminderGroup(
                          context: context,
                          ref: ref,
                          uid: user.uid,
                          reminders: reminders,
                          time: time,
                          reminderDays: reminderDays,
                        ),
                      ],
                      SettingsSection.general => [
                        _PreferenceGroup(
                          title: 'Uygulama tercihleri',
                          children: [
                            _PreferenceRow(
                              icon: Icons.palette_rounded,
                              title: 'Tema',
                              subtitle: _themeLabel(themeMode),
                              onTap: () => context.push('/settings/theme'),
                            ),
                            _PreferenceRow(
                              icon: Icons.notifications_active_rounded,
                              title: 'Hatırlatıcı',
                              subtitle: reminders
                                  ? 'Açık - ${_formatTime(time)}'
                                  : 'Kapalı',
                              onTap: () => context.push('/settings/reminders'),
                            ),
                            _PreferenceSwitch(
                              icon: Icons.calendar_month_rounded,
                              title: 'Hafta Pazartesi başlar',
                              subtitle: 'Takvim görünümü buna göre hizalanır.',
                              value: mondayFirst,
                              onChanged: (value) => _savePreference(
                                ref: ref,
                                uid: user.uid,
                                key: 'mondayFirst',
                                value: value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _PreferenceGroup(
                          title: 'Profil',
                          children: [
                            _PreferenceRow(
                              icon: Icons.person_rounded,
                              title: 'Profil adı',
                              subtitle: name,
                              onTap: () => context.push('/profile'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _PreferenceGroup(
                          title: 'Hesap',
                          children: [
                            _PreferenceRow(
                              icon: Icons.logout_rounded,
                              title: 'Çıkış yap',
                              subtitle: 'Bu cihazdaki oturumu kapat',
                              showChevron: false,
                              onTap: () async {
                                await ref.read(firebaseAuthProvider).signOut();
                                if (context.mounted) context.go('/gate');
                              },
                            ),
                          ],
                        ),
                      ],
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThemeGroup(WidgetRef ref, String uid, String themeMode) {
    return _PreferenceGroup(
      title: 'Tema',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'system',
                icon: Icon(Icons.phone_iphone_rounded),
                label: Text('Sistem'),
              ),
              ButtonSegment(
                value: 'dark',
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Koyu'),
              ),
              ButtonSegment(
                value: 'light',
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Açık'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (values) {
              _saveStringPreference(
                ref: ref,
                uid: uid,
                key: 'themeMode',
                value: values.first,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReminderGroup({
    required BuildContext context,
    required WidgetRef ref,
    required String uid,
    required bool reminders,
    required TimeOfDay time,
    required List<bool> reminderDays,
  }) {
    return _PreferenceGroup(
      title: 'Hatırlatıcılar',
      children: [
        _PreferenceSwitch(
          icon: Icons.notifications_active_rounded,
          title: 'Günlük hatırlatıcı',
          subtitle: 'Seçtiğin günlerde nazik bir bildirim al.',
          value: reminders,
          onChanged: (value) =>
              _savePreference(
                ref: ref,
                uid: uid,
                key: 'remindersEnabled',
                value: value,
              ).then(
                (_) => _syncReminders(
                  enabled: value,
                  time: time,
                  days: reminderDays,
                ),
              ),
        ),
        _PreferenceRow(
          icon: Icons.schedule_rounded,
          title: 'Hatırlatıcı saati',
          subtitle: _formatTime(time),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked == null) return;
            await _saveReminderTime(ref: ref, uid: uid, time: picked);
            await _syncReminders(
              enabled: reminders,
              time: picked,
              days: reminderDays,
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              const labels = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
              return FilterChip(
                label: Text(labels[index]),
                selected: reminderDays[index],
                onSelected: (value) async {
                  final next = [...reminderDays];
                  next[index] = value;
                  await _saveReminderDays(ref: ref, uid: uid, selected: next);
                  await _syncReminders(
                    enabled: reminders,
                    time: time,
                    days: next,
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _themeLabel(String themeMode) => switch (themeMode) {
  'system' => 'Sistem',
  'light' => 'Açık mod',
  _ => 'Koyu mod',
};

class _PreferenceGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PreferenceGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.mutedText(context, 0.62),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children.expand((child) sync* {
          yield child;
          if (child != children.last) {
            yield Divider(height: 18, color: AppTheme.glassBorder(context));
          }
        }),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText(context, 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.chevron_right_rounded, size: 32),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText(context, 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
