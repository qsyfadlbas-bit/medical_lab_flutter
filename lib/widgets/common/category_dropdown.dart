import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/utils/test_search.dart';

// ============================================================================
// قائمة منسدلة لأقسام التحاليل — بدل صف الشرائح الأفقي.
//
// ليش تبدّلت: الشرائح تحتاج سحب أفقي، ومع ١٢ قسم أو أكثر المستخدم ما يشوف
// شنو موجود. القائمة تعرض الكل مرة وحدة مع عدد التحاليل بكل قسم.
//
// الأقسام تجي ديناميكية من السيرفر، فالأيقونات تنختار بالكلمة المفتاحية
// مو بمطابقة تامة — حتى أي قسم جديد يضيفه الأدمن يطلع بأيقونة معقولة.
// ============================================================================

const Color _kPrimary = Color(0xFF047857); // LabTheme.primaryColor

/// أيقونة القسم — مطابقة بالكلمة المفتاحية بعد التطبيع،
/// حتى "الغدة الدرقية" و"غدة درقيه" ينطون نفس الأيقونة.
IconData categoryIcon(String category) {
  final c = normalizeArabic(category);

  if (c == 'الكل') return Icons.grid_view_rounded;

  const pairs = <List<String>>[
    ['دم انيميا هيموغلوبين', 'bloodtype'],
    ['كيمياء', 'science'],
    ['فايروس فيروس', 'coronavirus'],
    ['مناعه', 'shield'],
    ['بكتيريا جراثيم زرع', 'bug'],
    ['هرمون', 'insights'],
    ['فيتامين', 'eco'],
    ['كبد', 'hospital'],
    ['كلي كليه', 'water'],
    ['بول ادرار', 'opacity'],
    ['سكر', 'bubble'],
    ['درقيه غده', 'spa'],
    ['قلب', 'heart'],
    ['دهون دهن كوليسترول', 'grain'],
    ['اشعه تصوير سونار', 'scanner'],
    ['وظائف', 'monitor'],
    ['حمل خصوبه', 'child'],
    ['اخري', 'more'],
  ];

  for (final pair in pairs) {
    for (final key in pair[0].split(' ')) {
      // ⚠️ الكلمة المفتاحية تنطبّع هي هم. بلا هذا أي مفتاح بيه همزة أو
      //    تاء مربوطة ما يطابق أبداً — "وظائف" تصير "وظايف" بعد التطبيع
      //    فما تلگي نفسها، والقسم يطلع بالأيقونة العامة بصمت.
      if (c.contains(normalizeArabic(key))) return _iconByName(pair[1]);
    }
  }
  return Icons.medical_services_outlined;
}

IconData _iconByName(String name) {
  switch (name) {
    case 'bloodtype':
      return Icons.bloodtype;
    case 'science':
      return Icons.science;
    case 'coronavirus':
      return Icons.coronavirus;
    case 'shield':
      return Icons.shield_outlined;
    case 'bug':
      return Icons.bug_report;
    case 'insights':
      return Icons.insights;
    case 'eco':
      return Icons.eco;
    case 'hospital':
      return Icons.local_hospital_outlined;
    case 'water':
      return Icons.water_drop;
    case 'opacity':
      return Icons.opacity;
    case 'bubble':
      return Icons.bubble_chart;
    case 'spa':
      return Icons.spa;
    case 'heart':
      return Icons.favorite;
    case 'grain':
      return Icons.grain;
    case 'scanner':
      return Icons.scanner;
    case 'monitor':
      return Icons.monitor_heart;
    case 'child':
      return Icons.child_friendly;
    default:
      return Icons.more_horiz;
  }
}

class CategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final String selected;

  /// عدد التحاليل بكل قسم — يتعرض جنب الاسم. القسم الناقص يتعرض بلا رقم.
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    // لو القسم المختار انحذف من السيرفر ما ننهار — نرجع لأول قسم.
    // DropdownButton يرمي استثناء لو الـ value مو موجودة بالعناصر.
    final value =
        categories.contains(selected) ? selected : categories.first;

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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 420,
          borderRadius: BorderRadius.circular(18),
          dropdownColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          icon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: _kPrimary, size: 26),
          ),
          // الشكل المغلق — بلا علامة صح وبلا حشو زايد
          selectedItemBuilder: (context) =>
              categories.map((c) => _closedRow(c)).toList(),
          items: categories
              .map((c) => DropdownMenuItem<String>(
                    value: c,
                    child: _menuRow(c, c == value),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null && v != selected) onChanged(v);
          },
        ),
      ),
    );
  }

  /// الصف الي يبيّن والقائمة مسكّرة
  Widget _closedRow(String category) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(categoryIcon(category), size: 18, color: _kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
        ),
        _countBadge(category),
      ],
    );
  }

  /// صف داخل القائمة المفتوحة
  Widget _menuRow(String category, bool isSelected) {
    return Row(
      children: [
        Icon(
          categoryIcon(category),
          size: 20,
          color: isSelected ? _kPrimary : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? _kPrimary : Colors.black87,
            ),
          ),
        ),
        _countBadge(category),
        if (isSelected) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_rounded, size: 18, color: _kPrimary),
        ],
      ],
    );
  }

  Widget _countBadge(String category) {
    final n = counts[category];
    if (n == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$n',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _kPrimary.withOpacity(0.8),
        ),
      ),
    );
  }
}
