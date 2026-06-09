import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isEditingDisplayName = false;

  Future<void> _editDisplayName(String uid, String currentName) async {
    if (_isEditingDisplayName) return;
    _isEditingDisplayName = true;
    try {
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (_) => _EditDisplayNameDialog(initialName: currentName),
      );

      if (result == null || result.isEmpty) return;
      if (!mounted) return;

      await ref.read(firestoreProvider).collection('users').doc(uid).set({
        'displayName': result,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      _isEditingDisplayName = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final habitsAsync = ref.watch(habitsStreamProvider);
    final todayAsync = ref.watch(todayCompletionsProvider);
    final total30Async = ref.watch(last30DaysTotalCompletedProvider);
    final streak = ref.watch(streakSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
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
                  child: FilledButton(
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
                  final name =
                      (profile?['displayName'] as String?)?.trim().isNotEmpty ==
                          true
                      ? profile!['displayName'] as String
                      : 'Octy dostu';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _ProfileHeader(
                        name: name,
                        accountType: user.isAnonymous
                            ? 'Anonim hesap'
                            : 'Kayıtlı hesap',
                        onEdit: () => _editDisplayName(
                          user.uid,
                          name == 'Octy dostu' ? '' : name,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: habitsAsync.when(
                              loading: () => const _MetricCard(
                                label: 'Aktif alışkanlık',
                                value: '...',
                              ),
                              error: (e, _) => _MetricCard(
                                label: 'Aktif alışkanlık',
                                value: '!',
                                sublabel: 'Yüklenemedi',
                              ),
                              data: (habits) => _MetricCard(
                                label: 'Aktif alışkanlık',
                                value: '${habits.length}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: todayAsync.when(
                              loading: () => const _MetricCard(
                                label: 'Bugün',
                                value: '...',
                              ),
                              error: (e, _) => const _MetricCard(
                                label: 'Bugün',
                                value: '!',
                                sublabel: 'Yüklenemedi',
                              ),
                              data: (todayMap) => _MetricCard(
                                label: 'Bugün',
                                value:
                                    '${todayMap.values.where((v) => v).length}',
                                sublabel: 'tamamlandı',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Mevcut seri',
                              value: '${streak.current}',
                              sublabel: 'gün',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: total30Async.when(
                              loading: () => const _MetricCard(
                                label: 'Son 30 gün',
                                value: '...',
                              ),
                              error: (e, _) => const _MetricCard(
                                label: 'Son 30 gün',
                                value: '!',
                                sublabel: 'Yüklenemedi',
                              ),
                              data: (total) => _MetricCard(
                                label: 'Son 30 gün',
                                value: '$total',
                                sublabel: 'tamamlama',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Hesap bilgileri',
                        children: [
                          _InfoTile(
                            icon: Icons.verified_user_rounded,
                            title: 'Hesap türü',
                            value: user.isAnonymous
                                ? 'Anonim kullanıcı'
                                : 'E-posta ile giriş',
                          ),
                          _InfoTile(
                            icon: Icons.calendar_month_rounded,
                            title: 'Oluşturulma',
                            value: _formatDate(user.metadata.creationTime),
                          ),
                          _InfoTile(
                            icon: Icons.login_rounded,
                            title: 'Son giriş',
                            value: _formatDate(user.metadata.lastSignInTime),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Kısayollar',
                        children: [
                          _InfoTile(
                            icon: Icons.settings_rounded,
                            title: 'Ayarlar',
                            value: 'Tema, hatırlatıcı ve uygulama tercihleri',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push('/settings/general'),
                          ),
                          _InfoTile(
                            icon: Icons.logout_rounded,
                            title: 'Çıkış yap',
                            value: 'Bu cihazdaki oturumu kapat',
                            onTap: () async {
                              await ref.read(firebaseAuthProvider).signOut();
                              if (context.mounted) context.go('/gate');
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    return DateFormat('d MMMM y, HH:mm', 'tr_TR').format(date);
  }
}

class _EditDisplayNameDialog extends StatefulWidget {
  final String initialName;

  const _EditDisplayNameDialog({required this.initialName});

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adını düzenle'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          labelText: 'Görünen ad',
          hintText: 'Örnek: Emir',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String accountType;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.accountType,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.glassFill(context, dark: 0.08),
        border: Border.all(color: AppTheme.glassBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.glassBorder(context),
                width: 1.3,
              ),
            ),
            child: ClipOval(
              child: Image.asset('assets/octy/cool.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accountType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.64),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Adı düzenle',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;

  const _MetricCard({required this.label, required this.value, this.sublabel});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.glassFill(context),
        border: Border.all(color: AppTheme.glassBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.glassFill(context),
        border: Border.all(color: AppTheme.glassBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: onSurface.withValues(alpha: 0.62)),
      ),
      trailing: trailing,
    );
  }
}
