import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
 
class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
 
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });
 
  @override
  Widget build(BuildContext context) {
    final all = ['All', ...categories];
 
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = all[index];
          final isSelected =
              (cat == 'All' && selected.isEmpty) || cat == selected;
 
          return GestureDetector(
            onTap: () => onSelected(cat == 'All' ? '' : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primary : AppTheme.divider,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textMid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}