import 'package:flutter/material.dart';

// ============================================================================
// مربع بحث التحاليل + مثبّته فوق الشاشة.
//
// ليش ملف منفصل مو جوّا home_screen: حتى ينختبر لحاله (test/search_field_test)
// ونتأكد ما يطفح بأحجام خط النظام الكبيرة — بلا ما نحتاج نبني الشاشة كلها
// بشبكتها ونداءات السيرفر.
//
// الألوان مكررة هنا بدل ما نستورد LabTheme لأن LabTheme جوّا home_screen،
// واستيراده يصير دائري. لو غيّرت ألوان الثيم غيّرها هنا هم.
// ============================================================================

const Color _kPrimary = Color(0xFF047857); // LabTheme.primaryColor
const Color _kBackground = Color(0xFFECFDF5); // LabTheme.lightBackground

/// حقل البحث نفسه — أبيض بزوايا مدوّرة، أيقونة بحث يمين وزر مسح يسار.
class TestSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TestSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // نسمع للكنترولر بدل setState حتى زر المسح يبيّن/يختفي
      // بلا ما نعيد بناء الشاشة كلها بكل حرف
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            decoration: InputDecoration(
              isDense: true,

              // ⚠️ ثيم التطبيق (AppTheme.lightTheme.inputDecorationTheme)
              //    يفرض OutlineInputBorder + filled على كل TextField.
              //    كتابة border: none لحالها ما تلغي enabledBorder/focusedBorder،
              //    فينرسم صندوق أبيض بحدود جوّا صندوقنا = صندوقين متداخلين.
              //    لازم نلغي كل الحالات صراحةً.
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,

              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'دوّر عن تحليل… مثلاً: سكر، فيتامين د، CBC',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Colors.grey[500],
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _kPrimary,
                size: 22,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20, color: Colors.grey[600]),
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                        FocusScope.of(context).unfocus();
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// يثبّت حقل البحث تحت الـ AppBar حتى يبقى بالمتناول وانت تتصفح النتائج.
/// الارتفاع ثابت (ماكو تقلّص)، فـ minExtent == maxExtent.
class PinnedSearchBarHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  const PinnedSearchBarHeader({required this.child});

  /// 56 ارتفاع الحقل + 8 فوق + 8 تحت
  static const double height = 72;

  /// أقصى تكبير خط مسموح جوّا المثبّت.
  /// الارتفاع ثابت، فبلا هذا الحد الحقل يطفح ويطلع الشريط الأصفر
  /// على أجهزة المستخدمين الي مكبّرين خط النظام.
  static const double maxTextScale = 1.3;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // ظل خفيف يبيّن بس وقت ينثبّت فوق محتوى — يفصله بصرياً
    final pinned = shrinkOffset > 0 || overlapsContent;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        // خلفية صلبة، وإلا الشبكة تمر من وراه وينقرا مشوّش
        color: _kBackground,
        boxShadow: pinned
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(PinnedSearchBarHeader oldDelegate) =>
      oldDelegate.child != child;
}
