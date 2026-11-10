import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FilterCallback = void Function({
  String? responseCode,
  String? httpMethod,
  RouteLogModel? route,
  DateTime? fromDate,
  DateTime? toDate,
});

typedef DayRange = ({DateTime? from, DateTime? to});

const List<String> httpMethods = [
  'GET',
  'POST',
  'PUT',
  'PATCH',
  'DELETE',
  'HEAD',
  'OPTIONS',
];

///calendar rule: first click starts, second ends, one before the start becomes the new start
DayRange pickRangeDay(DayRange range, DateTime day) {
  if (range.from == null || range.to != null) return (from: day, to: null);
  if (day.isBefore(range.from!)) return (from: day, to: null);
  return (from: range.from, to: day);
}

String formatDayRange(DayRange range, String anyDate) {
  final format = app.dateFormatter.logsTimeS.format;
  if (range.from == null) return anyDate;
  return '${format(range.from!)} - ${range.to == null ? '…' : format(range.to!)}';
}

class LogsFilterDialog extends StatefulWidget {
  static void show({
    required LogsSearchFilters filters,
    required FilterCallback callback,
    required List<RouteLogModel> routes,
  }) {
    app.dialog.open(
      dialog: LogsFilterDialog(
        filters: filters,
        callback: callback,
        routes: routes,
      ),
    );
  }

  final LogsSearchFilters filters;
  final FilterCallback callback;
  final List<RouteLogModel> routes;

  const LogsFilterDialog({
    required this.filters,
    required this.callback,
    required this.routes,
    super.key,
  });

  @override
  State<LogsFilterDialog> createState() => _LogsFilterDialogState();
}

class _LogsFilterDialogState extends State<LogsFilterDialog> {
  static const _families = ['2', '3', '4', '5'];

  String? _status;
  String? _method;
  RouteLogModel? _route;
  DayRange _range = (from: null, to: null);
  final TextEditingController _exact = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filters = widget.filters;
    _status = filters.responseCode;
    _method = filters.httpMethod;
    _route = filters.route;
    _range = (from: filters.date?.fromDate, to: filters.date?.toDate);
    if (_status != null && !_families.contains(_status)) _exact.text = _status!;
  }

  @override
  void dispose() {
    _exact.dispose();
    super.dispose();
  }

  void _pickFamily(String family) => setState(() {
    _status = _status == family ? null : family;
    _exact.clear();
  });

  void _apply() {
    Navigator.of(context).pop();
    widget.callback(
      responseCode: _status,
      httpMethod: _method,
      route: _route,
      fromDate: _range.from,
      toDate: _range.to,
    );
  }

  Future<void> _openCalendar() async {
    final result = await app.dialog.open<DayRange>(
      dialog: _CalendarDialog(initial: _range),
      barrierColor: const Color(0x7308070c),
    );
    if (result != null) setState(() => _range = result);
  }

  Color _statusDot(String family) {
    final c = app.colors;
    return switch (family) {
      '2' => c.success,
      '3' => c.info,
      '4' => c.warn,
      _ => c.softRed,
    };
  }

  ///"Other": an exact code (or prefix) typed in the same row as the family chips
  Widget _buildExactCode(BuildContext context) {
    final c = app.colors;
    final selected = (_status?.length ?? 0) > 1;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: selected ? c.selected : c.outline),
    );
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _exact,
        autofocus: true,
        maxLines: 1,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: c.lilac,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        style: monoStyle(
          weight: FontWeight.w500,
          color: selected ? c.onSelected : c.text,
        ),
        onChanged: (value) =>
            setState(() => _status = value.isEmpty ? null : value),
        onSubmitted: (_) => _apply(),
        decoration: InputDecoration(
          hintText: context.intl.logFilters.exactCodeHint,
          hintStyle: monoStyle(weight: FontWeight.w500, color: c.textTertiary),
          semanticCounterText: context.intl.logFilters.exactCode,
          filled: true,
          fillColor: selected ? c.selected : const Color(0xff0f0d16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.lilac, width: 2),
          ),
        ),
      ),
    );
  }

  ///equal-width cells, [perRow] per row
  Widget _grid(List<Widget> cells, int perRow) => Column(
    children: [
      for (var i = 0; i < cells.length; i += perRow)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
          child: Row(
            children: [
              for (var col = 0; col < perRow; col++) ...[
                if (col > 0) const SizedBox(width: 6),
                Expanded(
                  child: i + col < cells.length
                      ? cells[i + col]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final filter = intl.logFilters;
    final hasDate = _range.from != null;
    return DialogTemplate(
      title: filter.filter,
      width: 520,
      footer: Row(
        children: [
          AppButton(
            label: filter.clearAll,
            kind: AppButtonKind.text,
            height: 44,
            onPressed: () => setState(() {
              _status = null;
              _method = null;
              _route = null;
              _range = (from: null, to: null);
              _exact.clear();
            }),
          ),
          const Spacer(),
          AppButton(
            label: intl.actions.cancel,
            kind: AppButtonKind.outlined,
            height: 44,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          AppButton(label: filter.applyFilters, height: 44, onPressed: _apply),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(filter.status),
          const SizedBox(height: 6),
          _grid([
            for (final family in _families)
              AppChoiceChip(
                label: '${family}xx',
                mono: true,
                dot: _statusDot(family),
                selected: _status == family,
                onTap: () => _pickFamily(family),
              ),
            _buildExactCode(context),
          ], 5),
          const SizedBox(height: 20),
          FieldLabel(filter.method),
          const SizedBox(height: 8),
          _grid([
            AppChoiceChip(
              label: filter.anyMethod,
              selected: _method == null,
              onTap: () => setState(() => _method = null),
            ),
            for (final method in httpMethods)
              AppChoiceChip(
                label: method,
                selected: _method == method,
                onTap: () => setState(() => _method = method),
              ),
          ], 4),
          const SizedBox(height: 20),
          FieldLabel(filter.route),
          const SizedBox(height: 8),
          _grid([
            AppChoiceChip(
              label: filter.anyRoute,
              align: Alignment.centerLeft,
              selected: _route == null,
              onTap: () => setState(() => _route = null),
            ),
            for (final route in widget.routes)
              Tooltip(
                message: route.routeName,
                child: AppChoiceChip(
                  label: route.routeName,
                  align: Alignment.centerLeft,
                  selected: _route == route,
                  onTap: () => setState(() => _route = route),
                ),
              ),
          ], 2),
          const SizedBox(height: 20),
          FieldLabel(filter.dateRange),
          const SizedBox(height: 6),
          Material(
            color: c.field,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.outline),
            ),
            child: InkWell(
              onTap: _openCalendar,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.only(left: 14, right: 12),
                child: Row(
                  children: [
                    app.assets.icons.general.calendar.build(
                      size: 18,
                      color: c.label,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formatDayRange(_range, filter.anyDate),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasDate ? c.text : c.textTertiary,
                        ),
                      ),
                    ),
                    app.assets.icons.general.chevronDown.build(
                      size: 18,
                      color: c.label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///pops the chosen range on Done, null on Cancel / close / barrier (the previous range stays)
class _CalendarDialog extends StatefulWidget {
  final DayRange initial;

  const _CalendarDialog({required this.initial});

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DayRange _range = widget.initial;
  late DateTime _month = DateTime(
    (widget.initial.from ?? DateTime.now()).year,
    (widget.initial.from ?? DateTime.now()).month,
  );

  DateTime get _today => DateTime.now().startOfDay;

  void _setRange(DateTime from, DateTime to) => setState(() {
    _range = (from: from, to: to);
    _month = DateTime(from.year, from.month);
  });

  void _shiftMonth(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  void _done() {
    final range = _range;
    Navigator.of(context).pop<DayRange>(
      range.from != null && range.to == null
          ? (from: range.from, to: range.from)
          : range,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final cal = intl.calendar;
    final today = _today;
    final hasFrom = _range.from != null;
    final hasBoth = hasFrom && _range.to != null;
    Widget presetStyle(String label, VoidCallback onPressed) => AppButton(
      label: label,
      kind: AppButtonKind.outlined,
      height: 30,
      radius: 8,
      fontSize: 12,
      onPressed: onPressed,
    );
    return DialogFrame(
      width: 380,
      color: c.popup,
      borderColor: c.outlineCard,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cal.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDayRange(_range, intl.logFilters.anyDate),
                          style: TextStyle(fontSize: 13, color: c.lilac),
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: app.assets.icons.actions.close,
                    tooltip: intl.actions.close,
                    size: 40,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      presetStyle(cal.today, () => _setRange(today, today)),
                      presetStyle(
                        cal.last7,
                        () => _setRange(
                          DateTime(today.year, today.month, today.day - 6),
                          today,
                        ),
                      ),
                      presetStyle(
                        cal.last30,
                        () => _setRange(
                          DateTime(today.year, today.month, today.day - 29),
                          today,
                        ),
                      ),
                      presetStyle(
                        cal.thisMonth,
                        () =>
                            _setRange(DateTime(today.year, today.month), today),
                      ),
                      AppButton(
                        label: cal.clear,
                        kind: AppButtonKind.text,
                        height: 30,
                        radius: 8,
                        fontSize: 12,
                        onPressed: () =>
                            setState(() => _range = (from: null, to: null)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppIconButton(
                        icon: app.assets.icons.general.chevronLeft,
                        tooltip: cal.previousMonth,
                        size: 36,
                        radius: 10,
                        onPressed: () => _shiftMonth(-1),
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          app.dateFormatter.month.format(_month),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: app.assets.icons.general.chevronRight,
                        tooltip: cal.nextMonth,
                        size: 36,
                        radius: 10,
                        onPressed: () => _shiftMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final day in cal.weekdays.split(','))
                        Expanded(
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: c.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ..._buildWeeks(today),
                  const SizedBox(height: 12),
                  Text(
                    hasBoth
                        ? cal.hintRestart
                        : (hasFrom ? cal.hintEnd : cal.hintStart),
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.raised)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: intl.actions.cancel,
                    kind: AppButtonKind.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(label: cal.done, autofocus: true, onPressed: _done),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///six weeks starting on Monday (dates built by day number, so DST never repeats a day)
  List<Widget> _buildWeeks(DateTime today) {
    final firstOffset = _month.weekday - 1;
    return [
      for (var week = 0; week < 6; week++)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              for (var weekday = 0; weekday < 7; weekday++)
                Expanded(
                  child: _buildDay(
                    DateTime(
                      _month.year,
                      _month.month,
                      1 - firstOffset + week * 7 + weekday,
                    ),
                    today,
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _buildDay(DateTime day, DateTime today) {
    final c = app.colors;
    final from = _range.from?.startOfDay;
    final to = _range.to?.startOfDay;
    final edge = day == from || day == to;
    final inRange =
        from != null && to != null && day.isAfter(from) && day.isBefore(to);
    final inMonth = day.month == _month.month;
    final isToday = day == today;
    return Semantics(
      button: true,
      selected: edge,
      label: app.dateFormatter.logsTimeS.format(day),
      excludeSemantics: true,
      onTap: () => setState(() => _range = pickRangeDay(_range, day)),
      child: Material(
        color: edge
            ? c.lilac
            : inRange
            ? c.lilac.withValues(alpha: 0.14)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(inRange ? 0 : 10),
          side: isToday && !edge
              ? const BorderSide(color: Color(0xff938f99))
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => setState(() => _range = pickRangeDay(_range, day)),
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 36,
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: edge || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: edge
                      ? c.onLilac
                      : inMonth
                      ? c.text
                      : const Color(0xff6f6c7b),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
