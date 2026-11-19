import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///up to 3 page numbers around the current one (1-based)
List<int> visiblePages({required int page, required int pageCount}) {
  final start = (page - 1).clamp(1, max(1, pageCount - 2)).toInt();
  return [for (var n = start; n < start + 3 && n <= pageCount; n++) n];
}

///the table's foot: what is shown, rows per page, the range and the pages
class LogsFooter extends StatelessWidget {
  final LogsCubit cubit;
  final bool booting;
  final bool filtering;

  const LogsFooter({
    required this.cubit,
    required this.booting,
    required this.filtering,
    super.key,
  });

  String _statusText(BuildContext context) {
    final logs = context.intl.logs;
    if (booting) return logs.loading;
    if (filtering) return logs.filtering;
    final total = cubit.totalElements;
    final count = total == 1
        ? logs.oneRequest
        : logs.manyRequests(count: logsCount(total, capped: cubit.totalCapped));
    return '$count${cubit.filters.isEmpty ? '' : logs.matchSuffix}${logs.rowHint}';
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final page = cubit.currentPage + 1;
    final pageCount = max(1, cubit.totalPages);
    final start = cubit.currentPage * cubit.pageSize;
    final total = cubit.totalElements;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.outlineSoft)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 12, height: 16 / 12, color: c.textTertiary),
        child: Row(
          children: [
            Expanded(child: Text(_statusText(context))),
            const SizedBox(width: 12),
            Text(intl.logs.rowsPerPage),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.outline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: cubit.pageSize,
                  isDense: true,
                  dropdownColor: c.popup,
                  borderRadius: BorderRadius.circular(8),
                  style: TextStyle(fontSize: 12, color: c.text),
                  iconSize: 16,
                  items: [
                    for (final size in const [10, 25, 50])
                      DropdownMenuItem(value: size, child: Text('$size')),
                  ],
                  onChanged: (size) {
                    if (size != null && size != cubit.pageSize) {
                      cubit.setPageSize(size);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              total == 0
                  ? intl.logs.emptyRange
                  : intl.logs.range(
                      start: '${start + 1}',
                      end: '${start + cubit.items.length}',
                      total: logsCount(total, capped: cubit.totalCapped),
                    ),
              style: TextStyle(
                color: c.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: app.assets.icons.general.chevronLeft,
              tooltip: intl.logs.previousPage,
              size: 32,
              iconSize: 16,
              radius: 8,
              onPressed: page <= 1
                  ? null
                  : () => cubit.goToPage(cubit.currentPage - 1),
            ),
            for (final number in visiblePages(page: page, pageCount: pageCount))
              _PageButton(
                number: number,
                current: number == page,
                onPressed: () => cubit.goToPage(number - 1),
              ),
            AppIconButton(
              icon: app.assets.icons.general.chevronRight,
              tooltip: intl.logs.nextPage,
              size: 32,
              iconSize: 16,
              radius: 8,
              onPressed: page >= pageCount
                  ? null
                  : () => cubit.goToPage(cubit.currentPage + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final int number;
  final bool current;
  final VoidCallback onPressed;

  const _PageButton({
    required this.number,
    required this.current,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final onTap = current ? null : onPressed;
    return Semantics(
      button: true,
      selected: current,
      label: context.intl.logs.page(page: number),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: current ? c.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 32),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: current ? c.onSelected : c.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
