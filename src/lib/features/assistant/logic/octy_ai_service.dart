import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final octyAiServiceProvider = Provider<OctyAiService>((ref) {
  return const OctyAiService();
});

class OctyAiContext {
  final int totalHabits;
  final int doneToday;
  final int weeklyDoneTotal;
  final int currentStreak;
  final List<String> pendingHabitTitles;

  const OctyAiContext({
    required this.totalHabits,
    required this.doneToday,
    required this.weeklyDoneTotal,
    required this.currentStreak,
    required this.pendingHabitTitles,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalHabits': totalHabits,
      'doneToday': doneToday,
      'weeklyDoneTotal': weeklyDoneTotal,
      'currentStreak': currentStreak,
      'pendingHabitTitles': pendingHabitTitles,
    };
  }
}

class OctyAiService {
  const OctyAiService();

  static const String _endpoint = String.fromEnvironment(
    'OCTY_AI_ENDPOINT',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
  );
  static const String _apiKey = String.fromEnvironment(
    'OCTY_AI_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );

  Future<String> generateReply({
    required String userMessage,
    required OctyAiContext context,
  }) async {
    final endpoint = _endpoint.trim();
    final apiKey = _apiKey.trim();

    if (endpoint.isEmpty) {
      debugPrint('OctyAiService: OCTY_AI_ENDPOINT is empty -> using fallback');
      return _fallbackReply(userMessage: userMessage, context: context);
    }

    final isGemini = endpoint.contains('generativelanguage.googleapis.com');

    if (isGemini) {
      try {
        final uri = Uri.parse('$endpoint?key=$apiKey');
        final systemPrompt = '''
Sen bir alışkanlık takip asistanısın. Kullanıcının alışkanlık verileri aşağıdadır:
- Toplam Alışkanlık Sayısı: ${context.totalHabits}
- Bugün Tamamlanan: ${context.doneToday}
- Bu Haftaki Toplam Tamamlanan: ${context.weeklyDoneTotal}
- Mevcut Seri (Streak): ${context.currentStreak} gün
- Henüz Yapılmamış Alışkanlıklar: ${context.pendingHabitTitles.isNotEmpty ? context.pendingHabitTitles.join(', ') : 'Hepsi tamamlandı'}

Kullanıcı mesajı: "$userMessage"

Lütfen kullanıcıya motive edici, samimi, kısa ve net bir Türkçe yanıt ver. Çok uzun paragraflar yazma, doğrudan hedefe odaklı ve yardımcı ol.
''';

        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt}
              ]
            }
          ]
        });

        final res = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 20));
        final raw = res.body;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          debugPrint('OctyAiService: Gemini API error: ${res.statusCode} raw=$raw');
          return _fallbackReply(userMessage: userMessage, context: context);
        }

        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final candidates = decoded['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final firstCandidate = candidates.first;
            if (firstCandidate is Map<String, dynamic>) {
              final content = firstCandidate['content'];
              if (content is Map<String, dynamic>) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final firstPart = parts.first;
                  if (firstPart is Map<String, dynamic>) {
                    final text = firstPart['text'];
                    if (text is String && text.trim().isNotEmpty) {
                      return text.trim();
                    }
                  }
                }
              }
            }
          }
        }
        return _fallbackReply(userMessage: userMessage, context: context);
      } catch (e) {
        debugPrint('OctyAiService: Gemini request failed ($e) -> using fallback');
        return _fallbackReply(userMessage: userMessage, context: context);
      }
    }

    try {
      final uri = Uri.parse(endpoint);

      // Prefer Firebase ID token for server-side proxy auth. Fall back to a static bearer only for dev.
      String? idToken;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          idToken = await user.getIdToken();
        }
      } catch (_) {
        // No-op: keep best-effort behavior.
      }

      final headers = <String, String>{'Content-Type': 'application/json'};

      final trimmedIdToken = (idToken ?? '').trim();
      if (trimmedIdToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $trimmedIdToken';
        if (apiKey.isNotEmpty) {
          headers['X-Octy-Dev-Key'] = apiKey;
        }
      } else if (apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiKey';
      }

      final body = jsonEncode({
        'message': userMessage,
        'context': context.toJson(),
      });

      final res = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
      final raw = res.body;

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint(
          'OctyAiService: non-2xx from AI endpoint: ${res.statusCode} raw=${raw.length > 300 ? raw.substring(0, 300) : raw}',
        );
        return _fallbackReply(userMessage: userMessage, context: context);
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final direct = decoded['reply'];
        if (direct is String && direct.trim().isNotEmpty) {
          return direct.trim();
        }

        final outputText = decoded['output_text'];
        if (outputText is String && outputText.trim().isNotEmpty) {
          return outputText.trim();
        }

        final choices = decoded['choices'];
        if (choices is List && choices.isNotEmpty) {
          final first = choices.first;
          if (first is Map<String, dynamic>) {
            final message = first['message'];
            if (message is Map<String, dynamic>) {
              final content = message['content'];
              if (content is String && content.trim().isNotEmpty) {
                return content.trim();
              }
            }
          }
        }
      }

      debugPrint(
        'OctyAiService: response JSON did not contain reply fields -> using fallback',
      );
      return _fallbackReply(userMessage: userMessage, context: context);
    } catch (e) {
      debugPrint('OctyAiService: request failed ($e) -> using fallback');
      return _fallbackReply(userMessage: userMessage, context: context);
    }
  }

  String _fallbackReply({
    required String userMessage,
    required OctyAiContext context,
  }) {
    final lower = userMessage.toLowerCase();
    final remaining = context.totalHabits - context.doneToday;
    final pending = context.pendingHabitTitles.take(2).toList();
    final firstPending = pending.isNotEmpty ? pending.first : null;

    if (context.totalHabits == 0) {
      return 'Henüz alışkanlık yok. Bugün sadece 1 tane ekle: küçük ve net bir hedef seç, sonra birlikte planlayalım.';
    }

    if (lower.contains('plan') || lower.contains('ne yap')) {
      if (firstPending != null) {
        return 'Bugün odak: "$firstPending". Şimdi 5 dakikalık mini bir tur başlat. Bitirince ikinci adım olarak kalanlardan birini seç.';
      }
      return 'Bugün harika gidiyorsun. Bir mini tekrar turu yap ve yarın için tek bir net saat belirle.';
    }

    if (lower.contains('motiv') ||
        lower.contains('zor') ||
        lower.contains('usengec')) {
      if (remaining <= 0) {
        return 'Bugün tamamsın, güzel iş. Zinciri korumak için yarın en kolay alışkanlıkla başla.';
      }
      return 'Şu an mükemmel olman gerekmiyor. Sadece 1 alışkanlığı tamamla ve ivmeyi aç; gerisi daha kolay gelecek.';
    }

    if (remaining <= 0) {
      return 'Bugün tüm hedefleri tamamladın. Bu ritmi korumak için yarın ilk alışkanlığa saat koyup sabitle.';
    }

    return 'Bugün ${context.doneToday}/${context.totalHabits} durumundasın. Şimdi tek bir alışkanlık seç ve 5 dakika uygula. Sonra bana "bitti" yaz, bir sonraki adımı vereyim.';
  }
}
