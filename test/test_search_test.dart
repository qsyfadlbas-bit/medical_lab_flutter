// اختبارات محرك بحث التحاليل — تشغيل: flutter test test/test_search_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_lab_flutter/utils/test_search.dart';

/// نموذج مبسّط يشبه MedicalTest بالضبط بالحقول الي يهتم بيها البحث
class _T {
  final String nameAr, nameEn, code, category;
  final List<String> keywords;
  const _T(this.nameAr, this.nameEn, this.code, this.category,
      [this.keywords = const []]);
}

TestSearchFields _fields(_T t) => TestSearchFields(
      nameAr: t.nameAr,
      nameEn: t.nameEn,
      code: t.code,
      category: t.category,
      keywords: t.keywords,
    );

// كتالوج يشبه الحقيقي
const _catalogue = <_T>[
  _T('صورة الدم الكاملة', 'Complete Blood Count', 'CBC', 'فحوصات الدم',
      ['دم', 'انيميا', 'فقر دم']),
  _T('سكر الدم الصائم', 'Fasting Blood Sugar', 'FBS', 'الكيمياء الحيوية',
      ['سكري', 'گلوكوز']),
  _T('السكر التراكمي', 'HbA1c', 'HBA1C', 'الكيمياء الحيوية', ['سكري']),
  _T('فيتامين د', 'Vitamin D', 'VITD', 'الفيتامينات', ['فيتامين', 'عظام']),
  _T('فيتامين ب12', 'Vitamin B12', 'B12', 'الفيتامينات', ['فيتامين', 'اعصاب']),
  _T('إنزيم الكبد ALT', 'Alanine Transaminase', 'ALT', 'وظائف الأعضاء',
      ['كبد']),
  _T('إنزيم الكبد AST', 'Aspartate Transaminase', 'AST', 'وظائف الأعضاء',
      ['كبد']),
  _T('وظائف الكلى', 'Renal Function Test', 'RFT', 'وظائف الأعضاء', ['كلى']),
  _T('هرمون الغدة الدرقية', 'Thyroid Stimulating Hormone', 'TSH', 'الهرمونات',
      ['درقية', 'غدة']),
  _T('فحص فيروس الكبد B', 'Hepatitis B Surface Antigen', 'HBSAG', 'فايروسات',
      ['التهاب الكبد']),
];

List<_T> search(String q) =>
    searchRank(_catalogue, q, fieldsOf: _fields).toList();

List<String> names(String q) => search(q).map((t) => t.nameAr).toList();

void main() {
  group('التطبيع', () {
    test('يوحّد الهمزات والتاء المربوطة والتشكيل', () {
      expect(normalizeArabic('أَحْمَد'), 'احمد');
      expect(normalizeArabic('الغدّة'), normalizeArabic('الغده'));
      expect(normalizeArabic('إنزيم'), 'انزيم');
    });

    test('يحوّل الأرقام الهندية والحروف العراقية', () {
      expect(normalizeArabic('ب١٢'), 'ب12');
      expect(normalizeArabic('گلوكوز'), 'كلوكوز');
    });

    test('يشيل الرموز ويوحّد المسافات', () {
      expect(normalizeArabic('  CBC-1   (دم) '), 'cbc 1 دم');
    });

    test('استعلام فاضي ما يفلتر شي', () {
      expect(search('').length, _catalogue.length);
      expect(search('   ').length, _catalogue.length);
    });
  });

  group('المطابقة الأساسية', () {
    test('الكود يطلع أول نتيجة', () {
      expect(search('CBC').first.code, 'CBC');
      expect(search('alt').first.code, 'ALT');
    });

    test('بحث بالعربي', () {
      expect(names('سكر'), contains('سكر الدم الصائم'));
      expect(names('سكر'), contains('السكر التراكمي'));
    });

    test('بحث بالإنجليزي', () {
      expect(search('vitamin').length, 2);
      expect(search('thyroid').first.code, 'TSH');
    });

    test('بحث بكلمة مفتاحية مو موجودة بالاسم', () {
      // "انيميا" موجودة بالـ keywords بس، مو باسم التحليل
      expect(names('انيميا'), contains('صورة الدم الكاملة'));
      // "كبد" مفتاحية لـ ALT و AST
      expect(names('كبد').length, greaterThanOrEqualTo(3));
    });

    test('حرف واحد يطابق كلمة كاملة بس', () {
      final r = names('فيتامين د');
      expect(r.first, 'فيتامين د');
    });

    test('الأرقام الهندية تطابق اللاتينية', () {
      expect(names('فيتامين ب١٢').first, 'فيتامين ب12');
    });
  });

  group('التسامح مع الأخطاء الإملائية', () {
    test('حرف ناقص', () {
      expect(names('فيتامي'), isNotEmpty); // بادئة
      expect(names('درقيه'), contains('هرمون الغدة الدرقية'));
    });

    test('حرف مقلوب أو زايد بكلمة طويلة', () {
      expect(names('الدرقيه'), contains('هرمون الغدة الدرقية'));
      expect(names('thyriod'), contains('هرمون الغدة الدرقية'));
    });

    test('كلمة قصيرة ما تتسامح — حتى ما تطلع نتائج عشوائية', () {
      // "دم" (حرفين) لازم تطابق نصياً بس، مو تشابه
      final r = names('دم');
      expect(r, contains('صورة الدم الكاملة'));
      expect(r, isNot(contains('هرمون الغدة الدرقية')));
    });
  });

  group('الترتيب', () {
    test('التطابق التام يسبق الجزئي', () {
      final r = search('فيتامين د');
      expect(r.first.code, 'VITD'); // "فيتامين د" بالضبط قبل "فيتامين ب12"
    });

    test('بداية الاسم تسبق الاحتواء', () {
      final r = names('سكر');
      // "سكر الدم الصائم" يبدي بالكلمة، "السكر التراكمي" لا
      expect(r.first, 'سكر الدم الصائم');
    });

    test('الكود التام يسبق كل شي', () {
      expect(search('B12').first.code, 'B12');
    });
  });

  group('حالات الحافة', () {
    test('استعلام ما يطابق شي يرجّع فاضي', () {
      expect(search('زززززز'), isEmpty);
    });

    test('كلمتين لازم الثنتين يطابقن', () {
      expect(names('سكر تراكمي'), ['السكر التراكمي']);
    });

    test('ثلاث كلمات يسمح بوحدة ما تطابق', () {
      expect(names('صورة الدم الكاملة'), contains('صورة الدم الكاملة'));
      expect(names('فحص صورة الدم'), contains('صورة الدم الكاملة'));
    });

    test('"ال" التعريف ما تكسر البحث', () {
      expect(names('الفيتامين'), isNotEmpty);
      expect(names('الكلى'), contains('وظائف الكلى'));
    });
  });
}
