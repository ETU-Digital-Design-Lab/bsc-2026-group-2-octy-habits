import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import 'logic/weekly_rate_engine.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final weeklyAsync = ref.watch(weeklyDoneCountsProvider);
    final weeklyDailyAsync = ref.watch(weeklyDailyTotalsProvider);
    final total30DaysAsync = ref.watch(last30DaysTotalCompletedProvider);
    final streak = ref.watch(streakSummaryProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.pageGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İstatistikler',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                habitsAsync.when(
                  loading: () => const _SkeletonCard(height: 250),
                  error: (e, _) => _ErrorCard(error: e),
                  data: (habits) {
                    return weeklyAsync.when(
                      loading: () => const _SkeletonCard(height: 250),
                      error: (e, _) => _ErrorCard(error: e),
                      data: (weeklyCounts) {
                        return weeklyDailyAsync.when(
                          loading: () => const _SkeletonCard(height: 250),
                          error: (e, _) => _ErrorCard(error: e),
                          data: (dailyTotals) {
                            final totalDone = weeklyCounts.values.fold<int>(
                              0,
                              (a, b) => a + b,
                            );
                            final totalTarget = habits.fold<int>(
                              0,
                              (a, h) => a + h.goalPerWeek,
                            );
                            final rate = weeklyCompletionRate(
                              totalDone: totalDone,
                              totalTarget: totalTarget,
                            );

                            return _GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Haftalık tamamlanma',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(rate * 100).round()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Bu haftaki ritmin',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.mutedText(context),
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  _WeeklyBars(dailyTotals: dailyTotals),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$totalDone tamam / $totalTarget hedef',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.mutedText(context),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                total30DaysAsync.when(
                  loading: () => const _SkeletonCard(height: 130),
                  error: (e, _) => _ErrorCard(error: e),
                  data: (total) {
                    final progress = (total / 50).clamp(0, 1).toDouble();
                    return _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam tamamlanan',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$total',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Son 30 gün',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.mutedText(context),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: AppTheme.mutedText(
                                context,
                                0.12,
                              ),
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Seri özeti',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StreakTile(
                        title: 'Mevcut seri',
                        value: streak.current,
                        color: const Color(0xFF3FA9F5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StreakTile(
                        title: 'En uzun seri',
                        value: streak.longest,
                        color: const Color(0xFFF0C43E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.glassFill(context),
        border: Border.all(color: AppTheme.glassBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.glassFill(context, dark: 0.05),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final List<int> dailyTotals;
  const _WeeklyBars({required this.dailyTotals});

  @override
  Widget build(BuildContext context) {
    final maxValue = dailyTotals.fold<int>(1, (m, v) => v > m ? v : m);
    const labels = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
    const colors = [
      Color(0xFF5EA7FF),
      Color(0xFF4FC6E8),
      Color(0xFF36D3B2),
      Color(0xFF76D26B),
      Color(0xFFFFC66D),
      Color(0xFFFF8A76),
      Color(0xFF9D8CFF),
    ];

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final value = i < dailyTotals.length ? dailyTotals[i] : 0;
          final ratio = (value / maxValue).clamp(0, 1).toDouble();
          final h = 28 + (60 * ratio);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 34,
                  height: h,
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText(context),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  const _StreakTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 30).clamp(0, 1).toDouble();
    return _GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  color: AppTheme.mutedText(context, 0.12),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: color,
                ),
                Text(
                  '$value',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '$value gün',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final Object error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Text(
        'Hata: $error',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
