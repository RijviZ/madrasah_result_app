import 'package:flutter/material.dart';
import '../utils/grading_engine.dart';

class AppPaginationBar extends StatelessWidget {
  const AppPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.lang,
    this.pageSizeOptions = const [10, 20, 50, 100],
  });

  final int currentPage;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final String lang;
  final List<int> pageSizeOptions;

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final totalPages = (totalItems / pageSize).ceil();
    final safePage = currentPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (safePage - 1) * pageSize + 1;
    final endIndex = (safePage * pageSize).clamp(1, totalItems);
    final isBn = lang == 'bn';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Page size dropdown & range info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBn ? 'প্রদর্শন: ' : 'Show: ',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              DropdownButton<int>(
                value: pageSizeOptions.contains(pageSize) ? pageSize : pageSizeOptions.first,
                isDense: true,
                underline: const SizedBox.shrink(),
                onChanged: (v) {
                  if (v != null) onPageSizeChanged(v);
                },
                items: pageSizeOptions.map((sz) {
                  return DropdownMenuItem<int>(
                    value: sz,
                    child: Text(
                      isBn ? '${GradingEngine.formatInt(sz, lang)}টি' : '$sz / page',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 12),
              Text(
                isBn
                    ? '${GradingEngine.formatInt(startIndex, lang)} - ${GradingEngine.formatInt(endIndex, lang)} (মোট ${GradingEngine.formatInt(totalItems, lang)}টি)'
                    : '$startIndex - $endIndex of $totalItems',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),

          // Pagination Navigation Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First Page
              IconButton(
                icon: const Icon(Icons.first_page_rounded, size: 20),
                tooltip: isBn ? 'প্রথম পৃষ্ঠা' : 'First Page',
                onPressed: safePage > 1 ? () => onPageChanged(1) : null,
              ),

              // Previous Page
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                tooltip: isBn ? 'পূর্ববর্তী' : 'Previous',
                onPressed: safePage > 1 ? () => onPageChanged(safePage - 1) : null,
              ),

              // Page indicator chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isBn
                      ? 'পৃষ্ঠা ${GradingEngine.formatInt(safePage, lang)} এর ${GradingEngine.formatInt(totalPages, lang)}'
                      : 'Page $safePage of $totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),

              // Next Page
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                tooltip: isBn ? 'পরবর্তী' : 'Next',
                onPressed: safePage < totalPages ? () => onPageChanged(safePage + 1) : null,
              ),

              // Last Page
              IconButton(
                icon: const Icon(Icons.last_page_rounded, size: 20),
                tooltip: isBn ? 'সর্বশেষ পৃষ্ঠা' : 'Last Page',
                onPressed: safePage < totalPages ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
