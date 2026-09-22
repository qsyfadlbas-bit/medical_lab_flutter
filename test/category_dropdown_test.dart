// اختبارات قائمة الأقسام — تشغيل: flutter test test/category_dropdown_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_lab_flutter/widgets/common/category_dropdown.dart';

// نفس أقسام التطبيق بالضبط
const _categories = [
  'الكل',
  'فحوصات الدم',
  'الكيمياء الحيوية',
  'السكر',
  'الدهون',
  'الكبد',
  'الكلى',
  'الغدة الدرقية',
  'فايروسات',
  'مناعة',
  'البكتيريا',
  'الهرمونات',
  'الفيتامينات',
  'وظائف الأعضاء',
  'أخرى',
];

const _counts = {
  'الكل': 46,
  'فحوصات الدم': 4,
  'الكيمياء الحيوية': 10,
  'السكر': 3,
  'الدهون': 0,
  'الكبد': 5,
  'الكلى': 0,
  'الغدة الدرقية': 3,
  'فايروسات': 3,
  'مناعة': 4,
  'البكتيريا': 2,
  'الهرمونات': 4,
  'الفيتامينات': 2,
  'وظائف الأعضاء': 2,
  'أخرى': 4,
};

Widget _harness({
  String selected = 'الكل',
  required ValueChanged<String> onChanged,
  List<String> categories = _categories,
  double textScale = 1.0,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: CategoryDropdown(
              categories: categories,
              selected: selected,
              counts: _counts,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // ✅ الأقسام الجديدة لازم تطلع بأيقوناتها الخاصة، مو بالأيقونة العامة.
  //    نفس الدالة تستعملها كارتات التحاليل، فلو انكسرت ينكسر الشكل بمكانين.
  test('كل قسم عنده أيقونته الخاصة', () {
    final generic = categoryIcon('اسم ما يشبه شي');
    const named = [
      'الكل',
      'فحوصات الدم',
      'الكيمياء الحيوية',
      'السكر',
      'الدهون',
      'الكبد',
      'الكلى',
      'الغدة الدرقية',
      'فايروسات',
      'مناعة',
      'البكتيريا',
      'الهرمونات',
      'الفيتامينات',
      'وظائف الأعضاء',
      'أخرى',
    ];

    for (final c in named) {
      expect(categoryIcon(c), isNot(generic),
          reason: 'القسم "$c" طلع بالأيقونة العامة');
    }

    // الأقسام المتقاربة ما تنخلط ببعض
    expect(categoryIcon('الكلى'), isNot(categoryIcon('الكبد')));
    expect(categoryIcon('السكر'), isNot(categoryIcon('الدهون')));

    // التطبيع يشتغل: نفس الأيقونة مهما انكتب الاسم
    expect(categoryIcon('الغده الدرقيه'), categoryIcon('الغدة الدرقية'));
    expect(categoryIcon('الكلي'), categoryIcon('الكلى'));
  });

  testWidgets('يعرض القسم المختار وعدده وهو مسكّر', (tester) async {
    await tester.pumpWidget(_harness(selected: 'الكيمياء الحيوية',
        onChanged: (_) {}));

    expect(find.text('الكيمياء الحيوية'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('الفتح يعرض الأقسام بقائمة، والباقي ينوصله بالسحب',
      (tester) async {
    await tester.pumpWidget(_harness(onChanged: (_) {}));

    await tester.tap(find.byType(CategoryDropdown));
    await tester.pumpAndSettle();

    // الأقسام الأولى تبيّن بلا سحب
    for (final c in _categories.take(6)) {
      expect(find.text(c), findsWidgets, reason: 'القسم "$c" ما ظهر بالقائمة');
    }

    // المنيو محدود الارتفاع (menuMaxHeight)، فآخر الأقسام تحتاج سحب.
    // نتأكد إنها موجودة فعلاً ومو مقطوعة.
    await tester.scrollUntilVisible(
      find.text('أخرى'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('أخرى'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('الاختيار يوصّل للـ onChanged', (tester) async {
    String? picked;
    await tester.pumpWidget(_harness(onChanged: (c) => picked = c));

    await tester.tap(find.byType(CategoryDropdown));
    await tester.pumpAndSettle();

    // قسم من الي بيّنين بلا سحب (القائمة محدودة الارتفاع)
    await tester.tap(find.text('السكر').last);
    await tester.pumpAndSettle();

    expect(picked, 'السكر');
  });

  testWidgets('اختيار نفس القسم ما يطلق onChanged', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
        _harness(selected: 'الكبد', onChanged: (_) => calls++));

    await tester.tap(find.byType(CategoryDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الكبد').last);
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  // ✅ DropdownButton يرمي استثناء لو الـ value مو موجودة بالعناصر.
  //    يصير لو القسم المحفوظ انحذف — لازم ما ينهار.
  testWidgets('قسم مختار مو موجود بالقائمة ما ينهار', (tester) async {
    await tester.pumpWidget(_harness(
      selected: 'قسم انحذف',
      onChanged: (_) {},
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('الكل'), findsOneWidget);
  });

  testWidgets('قائمة فاضية ما تنهار', (tester) async {
    await tester.pumpWidget(_harness(categories: const [], onChanged: (_) {}));
    expect(tester.takeException(), isNull);
  });

  testWidgets('الاسم الطويل ينقص بـ … بدل ما يطفح', (tester) async {
    await tester.pumpWidget(_harness(
      categories: const ['الكل', 'قسم اسمه طويل جداً جداً حتى يطفح الصف كله'],
      selected: 'قسم اسمه طويل جداً جداً حتى يطفح الصف كله',
      onChanged: (_) {},
    ));

    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('ما يطفح بتكبير خط ×$scale', (tester) async {
      await tester.pumpWidget(_harness(onChanged: (_) {}, textScale: scale));
      expect(tester.takeException(), isNull,
          reason: 'طفح تخطيط بتكبير خط ×$scale');
    });
  }
}
