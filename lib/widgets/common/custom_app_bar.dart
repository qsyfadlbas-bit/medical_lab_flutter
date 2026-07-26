import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool isExpanded;
  final bool isDense;
  final bool enabled;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? filledColor;
  final Color? borderColor;
  final double? elevation;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.isExpanded = false,
    this.isDense = false,
    this.enabled = true,
    this.icon,
    this.padding,
    this.borderRadius,
    this.filledColor,
    this.borderColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: filledColor ?? Theme.of(context).colorScheme.surface,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ??
                  (errorText != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: enabled ? onChanged : null,
              isExpanded: isExpanded,
              isDense: isDense,
              icon: icon ?? const Icon(Icons.arrow_drop_down),
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(12),
              elevation: elevation?.toInt() ?? 2,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              hint: hint != null
                  ? Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    )
                  : null,
              disabledHint: hint != null
                  ? Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class CustomSearchableDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final Widget? icon;
  final bool showSearchBox;
  final String? searchHint;

  const CustomSearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.icon,
    this.showSearchBox = true,
    this.searchHint,
  });

  @override
  State<CustomSearchableDropdown> createState() =>
      _CustomSearchableDropdownState<T>();
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions != null ? [...actions!, const Gap(8)] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomSearchableDropdownState<T>
    extends State<CustomSearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownMenuItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final child = item.child;
        if (child is Text) {
          return child.data?.toLowerCase().contains(searchText) ?? false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: widget.enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: widget.value,
              items: [
                if (widget.showSearchBox)
                  DropdownMenuItem<T>(
                    value: null,
                    enabled: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.searchHint ?? 'بحث...',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ..._filteredItems,
              ],
              onChanged: widget.enabled ? widget.onChanged : null,
              isExpanded: true,
              icon: widget.icon ?? const Icon(Icons.arrow_drop_down),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: widget.enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              hint: widget.hint != null
                  ? Text(
                      widget.hint!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
