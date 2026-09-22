// اختبارات ويدجت مربع البحث — تشغيل: flutter test test/search_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_lab_flutter/app/theme.dart';
import 'package:medical_lab_flutter/widgets/common/test_search_field.dart';

/// يبني الحقل جوّا مثبّته بالضبط مثل ما ينبنى بشاشة الفحوصات
Widget _harness({
  required TextEditingController controller,
  required ValueChanged<String> onChanged,
  double textScale = 1.0,
}) {
  return MaterialApp(
    // ثيم التطبيق الحقيقي — لأنه هو الي كان يحقن حدود زايدة بالحقل
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedSearchBarHeader(
                  child: TestSearchField(
                    controller: controller,
                    onChanged: onChanged,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => SizedBox(height: 80, child: Text('صف $i')),
                  childCount: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  late TextEditingController controller;
  late List<String> changes;

  setUp(() {
    controller = TextEditingController();
    changes = <String>[];
  });

  tearDown(() => controller.dispose());

  testWidgets('يبني بلا طفح ويعرض النص التوضيحي', (tester) async {
    await tester.pumpWidget(
        _harness(controller: controller, onChanged: changes.add));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.textContaining('دوّر عن تحليل'), findsOneWidget);
  });

  // ✅ الحماية من الانتكاسة: ثيم التطبيق يفرض OutlineInputBorder + filled
  //    على كل TextField، فينرسم صندوق أبيض بحدود جوّا صندوقنا (صندوقين
  //    متداخلين، شكل مخرّب). لازم كل حالات الحدود ملغية والتعبئة مطفية.
  testWidgets('ماكو صندوق ثاني جوّا الحقل من ثيم التطبيق', (tester) async {
    await tester.pumpWidget(
        _harness(controller: controller, onChanged: changes.add));

    final d = tester.widget<InputDecorator>(find.byType(InputDecorator));

    expect(d.decoration.filled, isFalse, reason: 'التعبئة البيضاء لسه شغالة');
    expect(d.decoration.border, InputBorder.none);
    expect(d.decoration.enabledBorder, InputBorder.none);
    expect(d.decoration.focusedBorder, InputBorder.none);
    expect(d.decoration.disabledBorder, InputBorder.none);
    expect(d.decoration.errorBorder, InputBorder.none);
    expect(d.decoration.focusedErrorBorder, InputBorder.none);
  });

  testWidgets('الكتابة توصّل للـ onChanged', (tester) async {
    await tester.pumpWidget(
        _harness(controller: controller, onChanged: changes.add));

    await tester.enterText(find.byType(TextField), 'سكر');
    await tester.pump();

    expect(changes, ['سكر']);
  });

  testWidgets('زر المسح يبيّن بس وقت يكو نص، ويفضّي الحقل', (tester) async {
    await tester.pumpWidget(
        _harness(controller: controller, onChanged: changes.add));

    // فاضي = ماكو زر مسح
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await tester.enterText(find.byType(TextField), 'فيتامين');
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changes.last, isEmpty);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('يبقى مثبّت فوق بعد التمرير', (tester) async {
    await tester.pumpWidget(
        _harness(controller: controller, onChanged: changes.add));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // لو ما كان pinned كان اختفى من الشجرة
    expect(find.byType(TestSearchField), findsOneWidget);
    expect(tester.getTopLeft(find.byType(TestSearchField)).dy,
        lessThan(PinnedSearchBarHeader.height));
    expect(tester.takeException(), isNull);
  });

  // ✅ الشغلة الي تنكسر بصمت: ارتفاع المثبّت ثابت، فلو خط النظام مكبّر
  //    الحقل يطفح ويطلع الشريط الأصفر. نتأكد إنه ما يصير.
  for (final scale in [1.0, 1.3, 2.0, 3.0]) {
    testWidgets('ما يطفح بتكبير خط النظام ×$scale', (tester) async {
      await tester.pumpWidget(_harness(
        controller: controller,
        onChanged: changes.add,
        textScale: scale,
      ));

      await tester.enterText(find.byType(TextField), 'فيتامين د');
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'طفح تخطيط بتكبير خط ×$scale');

      final box = tester.getSize(find.byType(TestSearchField));
      expect(box.height, lessThanOrEqualTo(PinnedSearchBarHeader.height),
          reason: 'الحقل تجاوز ارتفاع المثبّت بتكبير خط ×$scale');
    });
  }
}
