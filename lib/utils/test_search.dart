// ============================================================================
// محرك بحث التحاليل
//
// ليش ملف منفصل: home_screen.dart صار ~9,700 سطر، وهذا المنطق ما يحتاج
// يعرف شي عن الويدجت. مكتوب Generic حتى ما يستورد MedicalTest ويصير
// استيراد دائري (home_screen يستورد هذا الملف، مو العكس).
//
// شنو يسوي:
//   • تطبيع عربي (همزات/تاء مربوطة/تشكيل/أرقام هندية/حروف عراقية گ ڤ پ)
//   • مطابقة على: الاسم العربي، الإنجليزي، الكود، الكلمات المفتاحية،
//     التصنيف، والوصف — كل واحد بوزن مختلف
//   • تسامح مع الأخطاء الإملائية (مسافة تحرير محدودة)
//   • ترتيب النتائج حسب قوة التطابق، مو حسب ترتيب السيرفر
// ============================================================================

/// الحقول الي ينبحث بيها بأي عنصر. الشاشة تمرر دالة تحوّل عنصرها لهذا الشكل.
class TestSearchFields {
  final String nameAr;
  final String nameEn;
  final String code;
  final String category;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> keywords;

  const TestSearchFields({
    this.nameAr = '',
    this.nameEn = '',
    this.code = '',
    this.category = '',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.keywords = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// أوزان المطابقة — الأعلى يطلع أول بالنتائج.
// مسمّاة عمداً حتى لو حبيت تعدّل الترتيب تعرف شنو تلمس.
// ─────────────────────────────────────────────────────────────────────────────

// أوزان الاستعلام كامل (الجملة كلها)
const int _kCodeExact = 1200; // كتب الكود بالضبط: CBC
const int _kNameExact = 900; // كتب اسم التحليل بالضبط
const int _kNamePrefix = 500; // الاسم يبدي بالاستعلام
const int _kCodePrefix = 450; // الكود يبدي بالاستعلام
const int _kPhrase = 300; // الجملة كلها موجودة داخل الاسم

// أوزان الكلمة الواحدة (تنجمع لكل كلمة بالاستعلام)
const int _kTokCode = 260;
const int _kTokWordStart = 200; // كلمة بالاسم تبدي بهاي الكلمة
const int _kTokContains = 120;
const int _kTokKeyword = 100;
const int _kTokCategory = 50;
const int _kTokDesc = 35;
const int _kTokFuzzyBase = 90; // ناقص 25 لكل حرف خطأ
const int _kFuzzyPenalty = 25;

/// تطبيع نص عربي/إنجليزي للبحث.
/// يخلي "الفَحْص الدَّوري" و"الفحص الدوري" و"الفحص  الدوري" نفس الشي.
String normalizeArabic(String input) {
  var s = input.trim().toLowerCase();

  // إزالة التشكيل والمدّات
  s = s.replaceAll(
      RegExp('[ؐ-ًؚ-ٰٟۖ-ۭ]'), '');

  // توحيد الهمزات والحروف المتشابهة
  s = s.replaceAll(RegExp('[أإآٱ]'), 'ا');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll('ة', 'ه');
  s = s.replaceAll('ؤ', 'و');
  s = s.replaceAll('ئ', 'ي');
  s = s.replaceAll('ـ', ''); // التطويل

  // حروف عراقية/فارسية ينكتبن بالخطأ مكان العربية
  s = s.replaceAll('گ', 'ك');
  s = s.replaceAll('چ', 'ج');
  s = s.replaceAll('ڤ', 'ف');
  s = s.replaceAll('پ', 'ب');

  // أرقام هندية وهندية-فارسية → أرقام عادية (حتى "ب١٢" يطابق "B12")
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  const extendedIndic = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(arabicIndic[i], '$i');
    s = s.replaceAll(extendedIndic[i], '$i');
  }

  // أي شي مو حرف عربي/إنجليزي/رقم يصير مسافة (شرطات، أقواس، نقاط...)
  s = s.replaceAll(RegExp(r'[^؀-ۿa-z0-9 ]'), ' ');

  // مسافات متعددة → مسافة وحدة
  s = s.replaceAll(RegExp(r'\s+'), ' ');

  return s.trim();
}

/// هل الاستعلام يستاهل بحث أصلاً (مو فاضي بعد التطبيع)؟
bool hasSearchQuery(String query) => normalizeArabic(query).isNotEmpty;

/// يرجّع العناصر المطابقة مرتّبة من الأقوى للأضعف.
/// لو الاستعلام فاضي يرجّع القائمة نفسها بلا تغيير.
List<T> searchRank<T>(
  List<T> items,
  String query, {
  required TestSearchFields Function(T item) fieldsOf,
}) {
  final q = normalizeArabic(query);
  if (q.isEmpty) return items;

  final tokens = _expandTokens(q.split(' ').where((t) => t.isNotEmpty));
  if (tokens.isEmpty) return items;

  // بكلمة أو كلمتين نطلب تطابق الكل، بأكثر نسمح بكلمة وحدة ما تطابق
  final minRequired = tokens.length <= 2 ? tokens.length : tokens.length - 1;

  final scored = <_Scored<T>>[];
  for (final item in items) {
    final hay = _Haystack(fieldsOf(item));
    final score = _scoreItem(hay, q, tokens, minRequired);
    if (score > 0) {
      scored.add(_Scored<T>(item, score, hay.nameAr.length));
    }
  }

  scored.sort((a, b) {
    if (b.score != a.score) return b.score.compareTo(a.score);
    // نفس الدرجة: الاسم الأقصر أقرب للمقصود
    return a.nameLength.compareTo(b.nameLength);
  });

  return scored.map((e) => e.item).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// الداخليات
// ─────────────────────────────────────────────────────────────────────────────

class _Scored<T> {
  final T item;
  final int score;
  final int nameLength;
  const _Scored(this.item, this.score, this.nameLength);
}

/// النصوص المطبّعة لعنصر واحد — تنحسب مرة وحدة بدل ما تنعاد لكل كلمة
class _Haystack {
  final String nameAr;
  final String nameEn;
  final String code;
  final String category;
  final String descAr;
  final String descEn;
  final List<String> keywords;
  final List<String> words; // كل كلمات الاسمين + الكلمات المفتاحية (للتشابه)

  _Haystack._(this.nameAr, this.nameEn, this.code, this.category, this.descAr,
      this.descEn, this.keywords, this.words);

  factory _Haystack(TestSearchFields f) {
    final nameAr = normalizeArabic(f.nameAr);
    final nameEn = normalizeArabic(f.nameEn);
    final code = normalizeArabic(f.code);
    final keywords =
        f.keywords.map(normalizeArabic).where((k) => k.isNotEmpty).toList();

    final words = <String>{};
    for (final part in [nameAr, nameEn, ...keywords]) {
      for (final w in part.split(' ')) {
        if (w.length >= 3) words.add(w);
      }
    }
    if (code.isNotEmpty) words.add(code);

    return _Haystack._(
      nameAr,
      nameEn,
      code,
      normalizeArabic(f.category),
      normalizeArabic(f.descriptionAr),
      normalizeArabic(f.descriptionEn),
      keywords,
      words.toList(),
    );
  }
}

/// كل كلمة تنولّد منها نسخة بلا "ال" التعريف — حتى "الفيتامين" يطابق "فيتامين د"
List<List<String>> _expandTokens(Iterable<String> raw) {
  final out = <List<String>>[];
  for (final tok in raw) {
    final variants = <String>[tok];
    if (tok.length > 3 && tok.startsWith('ال')) {
      variants.add(tok.substring(2));
    }
    out.add(variants);
  }
  return out;
}

int _scoreItem(
    _Haystack h, String q, List<List<String>> tokens, int minRequired) {
  var total = 0;

  // ── مطابقة الاستعلام كامل ──
  if (h.code.isNotEmpty && h.code == q) {
    total += _kCodeExact;
  } else if (h.code.isNotEmpty && h.code.startsWith(q)) {
    total += _kCodePrefix;
  }

  if (h.nameAr == q || h.nameEn == q) {
    total += _kNameExact;
  } else if (h.nameAr.startsWith(q) || h.nameEn.startsWith(q)) {
    total += _kNamePrefix;
  } else if (h.nameAr.contains(q) || h.nameEn.contains(q)) {
    total += _kPhrase;
  }

  // ── مطابقة كل كلمة لحالها ──
  var matched = 0;
  for (final variants in tokens) {
    var best = 0;
    for (final tok in variants) {
      final s = _scoreToken(h, tok);
      if (s > best) best = s;
    }
    if (best > 0) {
      matched++;
      total += best;
    }
  }

  if (matched < minRequired) return 0;
  return total;
}

int _scoreToken(_Haystack h, String tok) {
  // حرف واحد (مثل "د" بـ "فيتامين د"): كلمة كاملة بس، وإلا يطابق نص المختبر
  if (tok.length == 1) {
    for (final w in h.nameAr.split(' ')) {
      if (w == tok) return _kTokWordStart;
    }
    for (final w in h.nameEn.split(' ')) {
      if (w == tok) return _kTokWordStart;
    }
    return 0;
  }

  if (h.code.isNotEmpty && (h.code == tok || h.code.startsWith(tok))) {
    return _kTokCode;
  }

  if (_hasWordStartingWith(h.nameAr, tok) ||
      _hasWordStartingWith(h.nameEn, tok)) {
    return _kTokWordStart;
  }

  if (h.nameAr.contains(tok) || h.nameEn.contains(tok)) {
    return _kTokContains;
  }

  for (final k in h.keywords) {
    if (k.contains(tok) || tok.contains(k)) return _kTokKeyword;
  }

  if (h.category.contains(tok)) return _kTokCategory;

  if (h.descAr.contains(tok) || h.descEn.contains(tok)) return _kTokDesc;

  // ── آخر محاولة: تشابه مع تسامح للأخطاء الإملائية ──
  final maxDist = _allowedDistance(tok.length);
  if (maxDist == 0) return 0;

  var bestDist = maxDist + 1;
  for (final w in h.words) {
    final d = _editDistance(w, tok, maxDist);
    if (d < bestDist) {
      bestDist = d;
      if (bestDist == 1) break; // ما راح نلگه أحسن من هيچ
    }
  }
  if (bestDist <= maxDist) {
    return _kTokFuzzyBase - (bestDist * _kFuzzyPenalty);
  }

  return 0;
}

/// كلمة قصيرة ما تتسامح مع الأخطاء (تصير نتائج عشوائية)،
/// الطويلة تتسامح أكثر
int _allowedDistance(int length) {
  if (length >= 7) return 2;
  if (length >= 4) return 1;
  return 0;
}

bool _hasWordStartingWith(String haystack, String tok) {
  if (haystack.isEmpty) return false;
  if (haystack.startsWith(tok)) return true;
  return haystack.contains(' $tok');
}

/// مسافة ليفنشتاين بقطع مبكر — لو تجاوزنا maxDist نطلع فوراً بدل ما نكمل
int _editDistance(String a, String b, int maxDist) {
  final la = a.length;
  final lb = b.length;
  if ((la - lb).abs() > maxDist) return maxDist + 1;
  if (la == 0) return lb;
  if (lb == 0) return la;

  var prev = List<int>.generate(lb + 1, (i) => i);
  var curr = List<int>.filled(lb + 1, 0);

  for (var i = 1; i <= la; i++) {
    curr[0] = i;
    var rowMin = curr[0];
    for (var j = 1; j <= lb; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = prev[j] + 1; // حذف
      final ins = curr[j - 1] + 1; // إضافة
      if (ins < v) v = ins;
      final sub = prev[j - 1] + cost; // استبدال
      if (sub < v) v = sub;
      curr[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > maxDist) return maxDist + 1; // ما يمكن ينزل بعدين
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }

  return prev[lb];
}
