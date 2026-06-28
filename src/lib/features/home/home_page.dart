import 'dart:math' as math;
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/habit.dart';
import '../../data/repositories/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _MascotNudge {
  final String text;
  final String emotionAsset;

  const _MascotNudge({required this.text, required this.emotionAsset});
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _customNudge;
  String? _customEmotion;
  Timer? _nudgeTimer;

  static const _nudgeOptions = <_MascotNudge>[
    _MascotNudge(
      text: 'Harikasın! Alışkanlık zincirini büyütmeye devam et! 🐙',
      emotionAsset: 'assets/octy/cool.png',
    ),
    _MascotNudge(
      text: 'Bugün harika bir gün, küçük adımlarla büyük farklar yaratabilirsin! ✨',
      emotionAsset: 'assets/octy/smile.png',
    ),
    _MascotNudge(
      text: 'Kendine zaman ayır, her başarılı gün bir adımla başlar! 💪',
      emotionAsset: 'assets/octy/smiling.png',
    ),
    _MascotNudge(
      text: 'Durmak yok, yola devam! Ben buradayım ve seni izliyorum! 👀',
      emotionAsset: 'assets/octy/wink.png',
    ),
    _MascotNudge(
      text: 'Sana sonuna kadar inanıyorum! Hadi bugünkü görevleri tamamlayalım! 🚀',
      emotionAsset: 'assets/octy/happy.png',
    ),
    _MascotNudge(
      text: 'Bir bardak su içtin mi? Kendine bakmayı unutma! 💧',
      emotionAsset: 'assets/octy/confusing.png',
    ),
    _MascotNudge(
      text: 'Küçük başarılar büyük hedeflerin temelidir. Harika gidiyorsun! 🌟',
      emotionAsset: 'assets/octy/cool.png',
    ),
    _MascotNudge(
      text: 'Octy her zaman arkanda! Hedeflerine ulaşacağını biliyorum! 🐙❤️',
      emotionAsset: 'assets/octy/love.png',
    ),
    _MascotNudge(
      text: 'Zorlandığında derin bir nefes al. Sadece 5 dakikalık mini bir başlangıç yap! 🧘‍♂️',
      emotionAsset: 'assets/octy/confusing.png',
    ),
    _MascotNudge(
      text: 'Her gün %1 daha iyi olmak, yarınları değiştirmek için en büyük sır! 📈',
      emotionAsset: 'assets/octy/wink.png',
    ),
  ];

  void _triggerMascotNudge() {
    _nudgeTimer?.cancel();
    final random = math.Random();
    final nudge = _nudgeOptions[random.nextInt(_nudgeOptions.length)];
    setState(() {
      _customNudge = nudge.text;
      _customEmotion = nudge.emotionAsset;
    });
    _nudgeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _customNudge = null;
          _customEmotion = null;
        });
      }
    });
  }

  String _getMascotSpeech(int completed, int total, String defaultInsight) {
    if (_customNudge != null) return _customNudge!;

    final double progress = total > 0 ? (completed / total) : 0.0;
    final hour = DateTime.now().hour;

    if (total == 0) {
      return 'İlk alışkanlığını ekle ve birlikte harika bir takip başlatalım! 🐙';
    }

    if (progress == 1.0) {
      return 'İşte bu! Bugün bütün hedeflerini tamamladın. Aşırı havalıyız, tebrikler! 😎';
    }

    if ((hour >= 22 || hour < 6) && progress == 0.0) {
      return 'Uykumuz geldi ama küçük de olsa bir adım atmaya ne dersin? 😴';
    }

    if (hour >= 21 && progress == 0.0) {
      return 'Bugün hiçbir şey yapmadık! Zinciri kırmana izin vermeyeceğim, çabuk başla! 😡';
    }

    if (hour >= 17 && progress == 0.0) {
      return 'Akşam yaklaşıyor ama hâlâ tek bir alışkanlık bile tamamlanmadı... Hadi, ufak bir adım atalım! 😢';
    }

    if (progress == 0.0) {
      if (hour >= 6 && hour < 11) {
        return 'Günaydın! Harika bir güne başlıyoruz. İlk adımı atmak için sabırsızlanıyorum! ☀️';
      }
      return 'Günün en verimli saatlerindeyiz. İlk halkayı tamamlayıp ivme kazanalım mı? 🐙';
    } else if (progress <= 0.15) {
      return 'Harika, ilk adımı attık bile! Devamı da çorap söküğü gibi gelecek. İnanıyorum sana! 🙂';
    } else if (progress <= 0.30) {
      return 'İki halkayı tamamladık bile! Sıradaki hedefimiz hangisi olsun, düşünüyoruz... 🤔';
    } else if (progress < 0.5) {
      return 'Güzel gidiyoruz! Adım adım hedefe yaklaşıyoruz. İvme kazanmaya başladık bile! 🚀';
    } else if (progress == 0.5) {
      return 'Yarısını tamamladık bile! Harika bir denge. İkinci yarı için enerjin var mı? 😉';
    } else if (progress <= 0.70) {
      return 'Çok iyi gidiyorsun! Halkaları tamamlamaya çok az kaldı, biraz daha gayret! 😃';
    } else {
      return 'Neredeyse bitti! Gayretine bayılıyorum, bugünü şampiyon gibi kapatacağız! 🐙❤️';
    }
  }

  String _getMascotEmotion(int completed, int total) {
    if (_customEmotion != null) return _customEmotion!;

    final double progress = total > 0 ? (completed / total) : 0.0;
    final hour = DateTime.now().hour;

    if (total == 0) {
      return 'assets/octy/octopus.png';
    }

    if (progress == 1.0) {
      return 'assets/octy/cool.png';
    }

    if ((hour >= 22 || hour < 6) && progress == 0.0) {
      return 'assets/octy/tired.png';
    }

    if (hour >= 21 && progress == 0.0) {
      return 'assets/octy/angry.png';
    }

    if (hour >= 17 && progress == 0.0) {
      return 'assets/octy/sad.png';
    }

    if (progress == 0.0) {
      final morning = hour >= 6 && hour < 11;
      return morning ? 'assets/octy/smile.png' : 'assets/octy/octopus.png';
    } else if (progress <= 0.15) {
      return 'assets/octy/smile.png';
    } else if (progress <= 0.30) {
      return 'assets/octy/confusing.png';
    } else if (progress < 0.5) {
      return 'assets/octy/happy.png';
    } else if (progress == 0.5) {
      return 'assets/octy/wink.png';
    } else if (progress <= 0.70) {
      return 'assets/octy/smiling.png';
    } else {
      return 'assets/octy/love.png';
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hata: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
            const SizedBox(height: 18),
            Text('User ID: ${FirebaseAuth.instance.currentUser?.uid}'),
            Text('Email: ${FirebaseAuth.instance.currentUser?.email}'),
            Text('Anonymous: ${FirebaseAuth.instance.currentUser?.isAnonymous}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/gate');
              },
              child: const Text('Çıkış Yap ve Girişe Dön'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final todayAsync = ref.watch(todayCompletionsProvider);
    final weeklyAsync = ref.watch(weeklyDoneCountsProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.pageGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: habitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(e),
            data: (habits) {
              return todayAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorState(e),
                data: (todayMap) {
                  return weeklyAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildErrorState(e),
                    data: (weeklyCounts) {
                      final prioritizedHabits = _prioritizedHabits(
                        habits: habits,
                        todayMap: todayMap,
                      );
                      final authUser = ref.watch(authStateProvider).valueOrNull;
                      final reminderText = authUser == null
                          ? null
                          : ref
                                .watch(userProfileProvider(authUser.uid))
                                .maybeWhen(
                                  data: (p) {
                                    if (p == null ||
                                        p['remindersEnabled'] == false) {
                                      return null;
                                    }
                                    final h = (p['reminderHour'] ?? 21) as int;
                                    final m = (p['reminderMinute'] ?? 0) as int;
                                    return 'Hatırlatıcı ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                                  },
                                  orElse: () => null,
                                );
                      final hiddenCount = math.max(0, habits.length - 8);
                      final doneCount = todayMap.values.where((v) => v).length;
                      final insight = ref.watch(octyInsightProvider);
                      return LayoutBuilder(
                        builder: (context, c) {
                          final contentWidth = math.min(c.maxWidth - 24, 460.0);
                          final isCompact = c.maxHeight < 820;
                          final compactScale = (c.maxHeight / 820).clamp(
                            0.84,
                            1.0,
                          );
                          final topSpacing =
                              (isCompact ? 6.0 : 10.0) * compactScale;
                          final sectionSpacing =
                              (isCompact ? 8.0 : 12.0) * compactScale;
                          final showReminder =
                              reminderText != null && c.maxHeight > 700;
                          final showHiddenCta =
                              hiddenCount > 0 && c.maxHeight > 860;
                          final boardSize = math
                              .max(
                                200.0,
                                math.min(
                                  contentWidth * 1.04,
                                  c.maxHeight * (isCompact ? 0.48 : 0.52),
                                ),
                              )
                              .toDouble();
                          return Center(
                            child: SizedBox(
                              width: contentWidth,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  12 * compactScale,
                                ),
                                child: Column(
                                  children: [
                                    Column(
                                      children: [
                                        _HomeTopGreeting(compact: isCompact),
                                        SizedBox(height: topSpacing),
                                        _WeekLineCalendar(compact: isCompact),
                                        if (showReminder) ...[
                                          SizedBox(height: topSpacing),
                                          Text(
                                            reminderText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.mutedText(
                                                    context,
                                                    0.58,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: sectionSpacing),
                                    Expanded(
                                      child: Center(
                                        child: SizedBox(
                                          width: boardSize,
                                          height: boardSize,
                                          child: _HomeRingBoard(
                                            habits: prioritizedHabits,
                                            todayMap: todayMap,
                                            weeklyCounts: weeklyCounts,
                                            onToggle: (habitId, doneToday) async {
                                              await ref
                                                  .read(
                                                    habitLogsRepositoryProvider,
                                                  )
                                                  .toggleToday(
                                                    habitId: habitId,
                                                    completed: !doneToday,
                                                  );
                                            },
                                            onTapMascot: _triggerMascotNudge,
                                            baseEmotionAsset: _getMascotEmotion(
                                              doneCount,
                                              habits.length,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    _ChatBubble(
                                      text: _getMascotSpeech(
                                        doneCount,
                                        habits.length,
                                        insight.microNudge,
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing),
                                    _TodayProgressBar(
                                      doneCount: doneCount,
                                      total: habits.length,
                                    ),
                                    if (showHiddenCta) ...[
                                      SizedBox(height: sectionSpacing),
                                      FilledButton.tonal(
                                        onPressed: () => context.go('/habits'),
                                        style: FilledButton.styleFrom(
                                          shape: const StadiumBorder(),
                                        ),
                                        child: const Text(
                                          'Tüm alışkanlıkları gör',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '+$hiddenCount tane daha',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.mutedText(
                                                context,
                                                0.58,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
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

  List<Habit> _prioritizedHabits({
    required List<Habit> habits,
    required Map<String, bool> todayMap,
  }) {
    final list = [...habits];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;

      final aDone = todayMap[a.id] == true;
      final bDone = todayMap[b.id] == true;
      if (aDone != bDone) return aDone ? 1 : -1;

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

class _HomeRingBoard extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, bool> todayMap;
  final Map<String, int> weeklyCounts;
  final Future<void> Function(String habitId, bool doneToday) onToggle;
  final VoidCallback onTapMascot;
  final String baseEmotionAsset;

  const _HomeRingBoard({
    required this.habits,
    required this.todayMap,
    required this.weeklyCounts,
    required this.onToggle,
    required this.onTapMascot,
    required this.baseEmotionAsset,
  });

  @override
  Widget build(BuildContext context) {
    final compactShownHabits = habits.take(8).toList();
    final itemCount = compactShownHabits.length;

    return LayoutBuilder(
      builder: (context, c) {
        final effectiveSize = math
            .min(c.maxWidth, c.maxHeight)
            .clamp(230.0, 460.0)
            .toDouble();

        final itemSize =
            effectiveSize *
            (itemCount <= 3 ? 0.29 : (itemCount <= 5 ? 0.27 : 0.235));

        final desiredCenterSize = itemCount == 0
            ? effectiveSize * 0.64
            : itemSize * 1.5;

        const gap = 10.0;
        final double minRadiusForNeighbors = itemCount <= 1
            ? 0.0
            : (itemSize + gap) / (2 * math.sin(math.pi / itemCount));
        final minRadiusForCenter =
            (desiredCenterSize / 2) + (itemSize / 2) + gap;
        final targetRadius = math.max(
          effectiveSize * 0.49,
          math.max(minRadiusForNeighbors, minRadiusForCenter),
        );

        final maxRadius = ((effectiveSize - itemSize) / 2) - gap;
        final radius = math.max(0.0, math.min(targetRadius, maxRadius));

        final maxCenterSize = math.max(
          0.0,
          2 * (radius - (itemSize / 2) - gap),
        );

        final centerSize = itemCount == 0
            ? desiredCenterSize
            : math.max(0.0, math.min(desiredCenterSize, maxCenterSize));

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: centerSize * 1.55,
              height: centerSize * 1.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF62D7FF).withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            _OctopusCenter(
              size: centerSize,
              completedCount: todayMap.values.where((v) => v).length,
              totalCount: habits.length,
              onTap: onTapMascot,
              baseEmotionAsset: baseEmotionAsset,
            ),
            if (itemCount == 0)
              Positioned(
                bottom: 16,
                child: Text(
                  'İlk alışkanlığını Alışkanlıklar sekmesinden ekle.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText(context, 0.72),
                  ),
                ),
              ),
            ...List.generate(itemCount, (i) {
              final angle = (-math.pi / 2) + (2 * math.pi * i / (itemCount == 0 ? 1 : itemCount));
              final dx = radius * math.cos(angle);
              final dy = radius * math.sin(angle);

              return Transform.translate(
                offset: Offset(dx, dy),
                child: SizedBox(
                  width: itemSize,
                  height: itemSize,
                  child: _HabitRingItem(
                    habit: compactShownHabits[i],
                    doneToday: todayMap[compactShownHabits[i].id] == true,
                    weeklyDone: weeklyCounts[compactShownHabits[i].id] ?? 0,
                    onToggle: () => onToggle(
                      compactShownHabits[i].id,
                      todayMap[compactShownHabits[i].id] == true,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _OctopusCenter extends StatefulWidget {
  final double size;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTap;
  final String baseEmotionAsset;

  const _OctopusCenter({
    required this.size,
    required this.completedCount,
    required this.totalCount,
    required this.onTap,
    required this.baseEmotionAsset,
  });

  @override
  State<_OctopusCenter> createState() => _OctopusCenterState();
}

class _OctopusCenterState extends State<_OctopusCenter>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatY;
  late final Animation<double> _floatScale;

  late final AnimationController _tapController;
  late final Animation<double> _tapRotation;
  late final Animation<double> _tapScale;
  late final Animation<double> _tapJump;

  Timer? _blinkTimer;
  bool _isBlinking = false;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();

    // Float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _floatScale = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Tap jump & spin animation
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _tapRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _tapController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _tapJump = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -28.0,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -28.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_tapController);

    _tapScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.82,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.82,
          end: 1.25,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.25,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_tapController);

    // Periodical Blinking
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 4500), (timer) {
      if (!mounted) return;
      if (_isTapped) return;

      setState(() {
        _isBlinking = true;
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        setState(() {
          _isBlinking = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _tapController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (_isTapped) return;
    widget.onTap();
    setState(() {
      _isTapped = true;
      _isBlinking = false;
    });
    _tapController.forward(from: 0.0).whenComplete(() {
      if (mounted) {
        setState(() {
          _isTapped = false;
        });
      }
    });
  }

  String _getAssetPath() {
    if (_isTapped) {
      return 'assets/octy/wink.png';
    }
    if (_isBlinking) {
      return 'assets/octy/smile.png';
    }
    return widget.baseEmotionAsset;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _tapController]),
        builder: (context, _) {
          final floatOffset = _floatY.value;
          final floatScaleVal = _floatScale.value;

          final tapJumpOffset = _tapJump.value;
          final tapScaleVal = _tapScale.value;
          final tapRotateVal = _tapRotation.value;

          final double combinedScale = floatScaleVal * tapScaleVal;
          final double combinedYOffset = floatOffset + tapJumpOffset;

          return Transform.translate(
            offset: Offset(0, combinedYOffset),
            child: Transform.rotate(
              angle: tapRotateVal,
              child: Transform.scale(
                scale: combinedScale,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.glassFill(context, dark: 0.045),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF62D7FF).withValues(alpha: 0.22),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.08),
                      child: Image.asset(
                        _getAssetPath(),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HabitRingItem extends StatelessWidget {
  final Habit habit;
  final bool doneToday;
  final int weeklyDone;
  final VoidCallback onToggle;

  const _HabitRingItem({
    required this.habit,
    required this.doneToday,
    required this.weeklyDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const ringPrimary = Color(0xFF90A5FF);
    const ringAccent = Color(0xFF7B61FF);
    final goal = habit.goalPerWeek <= 0 ? 1 : habit.goalPerWeek;
    final progress = (weeklyDone / goal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ringPrimary, ringAccent],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.all(2),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: ringAccent,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxWidth < 82;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          habit.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                height: 1.02,
                                fontSize: compact ? 13.2 : 14.4,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.15,
                              ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$weeklyDone/$goal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: compact ? 10.8 : 11.6,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (doneToday)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.9),
                ),
                child: const Icon(Icons.check, size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayProgressBar extends StatelessWidget {
  final int doneCount;
  final int total;
  const _TodayProgressBar({required this.doneCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (doneCount / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bugünkü ilerleme',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.mutedText(context, 0.72),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.mutedText(context, 0.12),
            color: const Color(0xFF7A8BFF),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  const _ChatBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppTheme.glassFill(context),
              border: Border.all(color: AppTheme.glassBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                height: 1.28,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.25,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          transform: Matrix4.rotationZ(0.785),
          decoration: BoxDecoration(
            color: AppTheme.glassFill(context),
            border: Border.all(color: AppTheme.glassBorder(context)),
          ),
        ),
      ],
    );
  }
}

class _WeekLineCalendar extends StatelessWidget {
  final bool compact;
  const _WeekLineCalendar({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    final days = List<DateTime>.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: List.generate(days.length, (i) {
        final d = days[i];
        final label = DateFormat.E('tr_TR').format(d);
        final isToday =
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: compact ? 5 : 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isToday
                    ? const Color(0xFF3F6FD2)
                    : AppTheme.glassFill(context, dark: 0.09),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF79BCFF)
                      : AppTheme.glassBorder(context),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style:
                        (compact
                                ? Theme.of(context).textTheme.labelMedium
                                : Theme.of(context).textTheme.labelLarge)
                            ?.copyWith(
                              color: isToday
                                  ? Colors.white
                                  : onSurface.withValues(alpha: 0.70),
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Container(
                    width: compact ? 30 : 34,
                    height: compact ? 30 : 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.16)
                          : (isDark
                                ? Colors.black.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.72)),
                    ),
                    child: Text(
                      '${d.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isToday
                            ? Colors.white
                            : onSurface.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HomeTopGreeting extends ConsumerWidget {
  final bool compact;
  const _HomeTopGreeting({this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hour = now.hour;
    final String salutation;
    if (hour >= 6 && hour < 12) {
      salutation = 'Günaydın';
    } else if (hour >= 12 && hour < 18) {
      salutation = 'İyi günler';
    } else if (hour >= 18 && hour < 24) {
      salutation = 'İyi akşamlar';
    } else {
      salutation = 'İyi geceler';
    }

    final authUser = ref.watch(authStateProvider).valueOrNull;
    final profile = authUser == null
        ? null
        : ref.watch(userProfileProvider(authUser.uid)).valueOrNull;
    final String displayName =
        (profile?['displayName'] as String?)?.trim().isNotEmpty == true
        ? (profile!['displayName'] as String)
        : 'Octy dostu';

    final formattedDate = DateFormat.yMMMMEEEEd('tr_TR').format(now);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$salutation, $displayName',
                style:
                    (compact
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.headlineMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.mutedText(context, 0.68),
                  fontSize: compact ? 13.5 : null,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/assistant'),
          child: Container(
            width: compact ? 64 : 76,
            height: compact ? 64 : 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.glassBorder(context)),
            ),
            child: ClipOval(
              child: Image.asset('assets/octy/cool.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }
}
