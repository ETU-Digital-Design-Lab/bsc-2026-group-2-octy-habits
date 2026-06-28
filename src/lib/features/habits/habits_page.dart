import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/habit.dart';
import '../../data/repositories/providers.dart';

enum _HabitFilter { all, done, pending }

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  _HabitFilter _filter = _HabitFilter.all;

  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    int goal = 4;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alışkanlık ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Örnek: Kitap oku',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: goal,
                items: [1, 2, 3, 4, 5, 6, 7]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => goal = v ?? 4,
                decoration: const InputDecoration(labelText: 'Haftalık hedef'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final title = titleCtrl.text.trim();
      if (title.isNotEmpty) {
        await ref
            .read(habitsRepositoryProvider)
            .addHabit(title: title, goalPerWeek: goal, colorValue: 0xFF7C5CFF);
      }
    }
    titleCtrl.dispose();
  }

  Future<void> _showEditDialog(Habit habit) async {
    final titleCtrl = TextEditingController(text: habit.title);
    int goal = habit.goalPerWeek;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alışkanlığı düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Başlık'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: goal,
                items: [1, 2, 3, 4, 5, 6, 7]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => goal = v ?? goal,
                decoration: const InputDecoration(labelText: 'Haftalık hedef'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final title = titleCtrl.text.trim();
      if (title.isNotEmpty) {
        await ref
            .read(habitsRepositoryProvider)
            .updateHabit(habitId: habit.id, title: title, goalPerWeek: goal);
      }
    }
    titleCtrl.dispose();
  }

  Future<void> _confirmDeleteHabit(Habit habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alışkanlığı sil'),
          content: Text(
            '"${habit.title}" silinecek. Bu alışkanlığa ait kayıtlar da kaldırılır.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    try {
      final repo = ref.read(habitsRepositoryProvider);
      final snapshot = await repo.deleteHabitWithSnapshot(habit.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final controller = messenger.showSnackBar(
        SnackBar(
          content: const Text('Alışkanlık silindi.'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () async {
              await repo.restoreDeletedHabit(snapshot);
            },
          ),
        ),
      );
      await controller.closed;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme başarısız: $e')));
    }
  }

  Future<void> _togglePinHabit(Habit habit) async {
    await ref
        .read(habitsRepositoryProvider)
        .setPinned(habitId: habit.id, pinned: !habit.isPinned);
  }

  Future<void> _onReorderAllHabits(
    List<Habit> habits,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = [...habits];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    await ref
        .read(habitsRepositoryProvider)
        .updateHabitOrder(reordered.map((h) => h.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final todayAsync = ref.watch(todayCompletionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alışkanlıklar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: 'Alışkanlık ekle',
        child: const Icon(Icons.add_rounded),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.pageGradient(Theme.of(context).brightness),
        ),
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (habits) {
            return todayAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (todayMap) {
                final sorted = _sortHabits(habits);
                final filtered = _applyFilter(sorted, todayMap, _filter);
                final doneCount = habits
                    .where((h) => todayMap[h.id] == true)
                    .length;
                final pendingCount = habits.length - doneCount;

                if (habits.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Henüz alışkanlık yok. İlk hedefini ekleyerek başlayabilirsin.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.mutedText(context),
                              height: 1.3,
                            ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        buildDefaultDragHandles: _filter == _HabitFilter.all,
                        onReorder: (oldIndex, newIndex) async {
                          if (_filter != _HabitFilter.all) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sıralama sadece Tümü sekmesinde çalışır.',
                                ),
                              ),
                            );
                            return;
                          }
                          await _onReorderAllHabits(
                            filtered,
                            oldIndex,
                            newIndex,
                          );
                        },
                        header: Column(
                          children: [
                            _TopSummary(
                              total: habits.length,
                              done: doneCount,
                              pending: pendingCount,
                            ),
                            const SizedBox(height: 12),
                            _FilterBar(
                              current: _filter,
                              onChanged: (f) => setState(() => _filter = f),
                            ),
                            const SizedBox(height: 12),
                            if (_filter == _HabitFilter.all)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Sıralamayı değiştirmek için kartı basılı tutup sürükle.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.mutedText(
                                          context,
                                          0.60,
                                        ),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Center(
                                  child: Text(
                                    'Bu listede alışkanlık yok.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final h = filtered[i];
                          final doneToday = todayMap[h.id] == true;
                          return Padding(
                            key: ValueKey(h.id),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HabitCard(
                              habit: h,
                              doneToday: doneToday,
                              onTap: () => context.push(
                                '/habit/${h.id}/calendar',
                                extra: h.title,
                              ),
                              onEdit: () => _showEditDialog(h),
                              onPin: () => _togglePinHabit(h),
                              onDelete: () => _confirmDeleteHabit(h),
                              onToggle: (v) async {
                                await ref
                                    .read(habitLogsRepositoryProvider)
                                    .toggleToday(habitId: h.id, completed: v);
                                ref
                                    .read(appEventsRepositoryProvider)
                                    .logEventSafe(
                                      type: 'habit_toggle',
                                      data: {'habitId': h.id, 'completed': v},
                                    );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Habit> _applyFilter(
    List<Habit> habits,
    Map<String, bool> todayMap,
    _HabitFilter filter,
  ) {
    switch (filter) {
      case _HabitFilter.done:
        return habits.where((h) => todayMap[h.id] == true).toList();
      case _HabitFilter.pending:
        return habits.where((h) => todayMap[h.id] != true).toList();
      case _HabitFilter.all:
        return habits;
    }
  }

  List<Habit> _sortHabits(List<Habit> habits) {
    final list = [...habits];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }

      final aCreated = a.createdAt;
      final bCreated = b.createdAt;
      if (aCreated != null && bCreated != null) {
        return bCreated.compareTo(aCreated);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }
}

class _TopSummary extends StatelessWidget {
  final int total;
  final int done;
  final int pending;

  const _TopSummary({
    required this.total,
    required this.done,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(label: 'Toplam', value: '$total'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricChip(label: 'Tamamlandı', value: '$done'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricChip(label: 'Kalan', value: '$pending'),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.glassFill(context),
        border: Border.all(color: AppTheme.glassBorder(context)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 11.5,
              color: AppTheme.mutedText(context, 0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _HabitFilter current;
  final ValueChanged<_HabitFilter> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.glassFill(context, dark: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _FilterButton(
            selected: current == _HabitFilter.all,
            title: 'Tümü',
            onTap: () => onChanged(_HabitFilter.all),
          ),
          _FilterButton(
            selected: current == _HabitFilter.done,
            title: 'Tamam',
            onTap: () => onChanged(_HabitFilter.done),
          ),
          _FilterButton(
            selected: current == _HabitFilter.pending,
            title: 'Kalan',
            onTap: () => onChanged(_HabitFilter.pending),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool selected;
  final String title;
  final VoidCallback onTap;

  const _FilterButton({
    required this.selected,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.glassFill(context, dark: 0.14) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool doneToday;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _HabitCard({
    required this.habit,
    required this.doneToday,
    required this.onTap,
    required this.onEdit,
    required this.onPin,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.glassFill(context),
            border: Border.all(color: AppTheme.glassBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(habit.colorValue),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Haftalık hedef: ${habit.goalPerWeek}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (habit.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 18,
                    color: const Color(0xFFF0C43E).withValues(alpha: 0.9),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'pin') onPin();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem<String>(
                    value: 'pin',
                    child: Text(
                      habit.isPinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
                    ),
                  ),
                  PopupMenuItem<String>(value: 'delete', child: Text('Sil')),
                ],
              ),
              Checkbox(
                value: doneToday,
                onChanged: (v) => onToggle(v ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
