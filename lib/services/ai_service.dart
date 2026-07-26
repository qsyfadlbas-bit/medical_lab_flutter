import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_lab_flutter/services/api_service.dart';

/// خدمة المساعد الطبي الذكي — ثلاث طبقات:
///   (1) الخادم: كاش → Gemini → مرشّح محلي على الخادم  (المفتاح محفوظ في الخادم)
///   (2) بديل محلي كامل على الجهاز يعمل بدون إنترنت (يطابق منطق الخادم)
/// لا ترمي استثناءً أبداً — تُعيد دائماً نتيجة قابلة للعرض.
///
/// شكل النتيجة المُعادة (متوافق مع askAIAssistant في home_screen):
///   {'response': String, 'suggestedTests': List<String>, 'source': String}
/// حيث suggestedTests قائمة أكواد تحاليل، وsource ∈ {ai, cache, local}.
class AiService {
  final ApiService _api = ApiService();

  // مفتاح تخزين الكتالوج محلياً (للعمل أوفلاين)
  static const String _catalogueKey = 'ai_catalogue_cache';

  /// الاقتراح الذكي.
  /// [symptoms] وصف الأعراض. [catalogue] قائمة التحاليل الحالية (MedicalTest.toJson()).
  Future<Map<String, dynamic>> suggest(
    String symptoms, {
    List<Map<String, dynamic>> catalogue = const [],
  }) async {
    final text = symptoms.trim();
    if (text.isEmpty) {
      return {
        'response': 'يرجى كتابة الأعراض أو سؤالك أولاً.',
        'suggestedTests': <String>[],
        'source': 'local',
      };
    }

    // خزّن الكتالوج كلما توفّر — ليعمل البديل المحلي لاحقاً بدون إنترنت
    if (catalogue.isNotEmpty) {
      await _cacheCatalogue(catalogue);
    }

    // (1) المحاولة عبر الخادم
    try {
      final res = await _api.post('/ai/suggest', {'symptoms': text});
      final body = ApiService.safeJsonDecode(res);
      if (body == null) throw Exception('استجابة فارغة من الخادم');
      final bool invalid = body['_invalid'] == true;

      if (!invalid && res.statusCode == 200 && body['success'] == true) {
        final List data =
            (body['data'] is List) ? body['data'] as List : const [];
        final codes = data
            .map((e) => (e is Map ? e['code'] : null)?.toString())
            .whereType<String>()
            .where((c) => c.isNotEmpty)
            .toList();

        final response = (body['response'] ??
                body['note'] ??
                'إليك بعض التحاليل التي قد تناسب حالتك.')
            .toString();

        return {
          'response': response,
          'suggestedTests': codes,
          'source': (body['source'] ?? 'ai').toString(),
        };
      }
      // الخادم رد بفشل/HTML/صيغة غير صحيحة → ننزل للبديل المحلي
    } catch (_) {
      // انقطاع إنترنت / مهلة / أي خطأ → ننزل للبديل المحلي
    }

    // (2) البديل المحلي الكامل على الجهاز
    return _localSuggest(text, catalogue);
  }

  // ============================================================
  // البديل المحلي — مطابقة بالكلمات المفتاحية على الكتالوج
  // ============================================================
  Future<Map<String, dynamic>> _localSuggest(
      String symptoms, List<Map<String, dynamic>> catalogue) async {
    var cat = catalogue;
    if (cat.isEmpty) cat = await _loadCachedCatalogue();

    final norm = _normalizeAr(symptoms);
    final tokens = norm.split(' ').where((t) => t.length >= 2).toList();

    final scored = <Map<String, dynamic>>[];
    if (tokens.isNotEmpty) {
      for (final t in cat) {
        final code = (t['code'] ?? '').toString();
        if (code.isEmpty) continue;

        final hay = _normalizeAr(
            '${t['nameAr'] ?? ''} ${t['nameEn'] ?? ''} ${t['category'] ?? ''}');
        final kwList =
            (t['keywords'] is List) ? t['keywords'] as List : const [];
        final kw = _normalizeAr(kwList.map((e) => e.toString()).join(' '));

        int score = 0;
        for (final tok in tokens) {
          if (kw.contains(tok)) score += 3; // كلمة مفتاحية
          if (hay.contains(tok)) score += 2; // الاسم/الفئة
        }
        if (score > 0) scored.add({'code': code, 'score': score});
      }
      scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    }

    final codes = scored.take(6).map((e) => e['code'] as String).toList();

    final response = codes.isNotEmpty
        ? 'بناءً على أعراضك، قد تناسبك هذه التحاليل. ننصح بمراجعة الطبيب لتأكيد ما يلزم.\n(عرض بدون إنترنت — اقتراح مبدئي)'
        : 'تعذّر الوصول إلى الخادم ولم أجد تطابقاً واضحاً للأعراض. تأكّد من الإنترنت أو تواصل مع المختبر.';

    return {
      'response': response,
      'suggestedTests': codes,
      'source': 'local',
    };
  }

  // ============================================================
  // تخزين/تحميل الكتالوج محلياً
  // ============================================================
  Future<void> _cacheCatalogue(List<Map<String, dynamic>> catalogue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final light = catalogue
          .map((t) => {
                'code': t['code'],
                'nameAr': t['nameAr'],
                'nameEn': t['nameEn'],
                'category': t['category'],
                'keywords': t['keywords'],
              })
          .toList();
      await prefs.setString(_catalogueKey, jsonEncode(light));
    } catch (_) {/* تجاهل */}
  }

  Future<List<Map<String, dynamic>>> _loadCachedCatalogue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_catalogueKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // تطبيع النص العربي — مطابق لمنطق الخادم (ai_normalize)
  // ============================================================
  String _normalizeAr(String s) {
    s = s.trim().toLowerCase();
    // إزالة التشكيل
    s = s.replaceAll(
        RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    // توحيد الحروف
    s = s.replaceAll(RegExp('[أإآٱ]'), 'ا');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ئ', 'ي');
    s = s.replaceAll('ـ', ''); // التطويل
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }
}
