import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///the search with the active filters as chips, and the Filters button
class LogsToolbar extends StatelessWidget {
  final LogsCubit cubit;
  final TextEditingController search;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  const LogsToolbar({
    required this.cubit,
    required this.search,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final intl = context.intl;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: app.colors.raised)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: search,
              hint: intl.logs.search,
              clearLabel: intl.actions.clearSearch,
              height: 44,
              fontSize: 14,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
              onClear: onClear,
              chips: _activeChips(context),
            ),
          ),
          const SizedBox(width: 10),
          LogsFilterButton(
            count: cubit.filters.filterCount,
            onPressed: () => LogsFilterDialog.show(
              filters: cubit.filters,
              routes: cubit.routes,
              callback: cubit.applyFilter,
            ),
          ),
        ],
      ),
    );
  }

  ///in this order: method, route, status, date
  List<Widget> _activeChips(BuildContext context) {
    final filters = cubit.filters;
    final format = app.dateFormatter.logsTimeS.format;
    final from = filters.date?.fromDate;
    final to = filters.date?.toDate;
    final status = filters.responseCode;
    Widget chip(String label, LogFilterKind kind) =>
        LogsFilterChip(label: label, onRemove: () => cubit.removeFilter(kind));
    return [
      if (filters.hasHttpMethod)
        chip(filters.httpMethod!, LogFilterKind.method),
      if (filters.hasRoute) chip(filters.route!.routeName, LogFilterKind.route),
      if (status != null)
        chip(status.length == 1 ? '${status}xx' : status, LogFilterKind.status),
      if (filters.hasDate)
        chip(
          from != null && to != null
              ? '${format(from)} - ${format(to)}'
              : from != null
              ? context.intl.logFilters.chipFrom(date: format(from))
              : context.intl.logFilters.chipUntil(date: format(to!)),
          LogFilterKind.date,
        ),
    ];
  }
}

///one active filter inside the search, with its ×
class LogsFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const LogsFilterChip({
    required this.label,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.text,
            ),
          ),
          const SizedBox(width: 2),
          AppIconButton(
            icon: app.assets.icons.actions.close,
            tooltip: context.intl.logs.removeFilter(label: label),
            size: 24,
            iconSize: 13,
            radius: 6,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

///Filters, lilac with the count while some are on
class LogsFilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const LogsFilterButton({
    required this.count,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final active = count > 0;
    //the semantics node replaces the child's, so it carries the tap itself
    return Semantics(
      button: true,
      label: intl.logs.filtersActive(count: count),
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: active ? c.lilac.withValues(alpha: 0.12) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? c.lilac.withValues(alpha: 0.5) : c.outline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 14, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                app.assets.icons.general.filter.build(size: 17, color: c.text),
                const SizedBox(width: 8),
                Text(
                  intl.logs.filters,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.lilac,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.onLilac,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
