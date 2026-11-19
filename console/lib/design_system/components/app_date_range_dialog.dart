import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///a day range: from and to, either can be empty
typedef DayRange = ({DateTime? from, DateTime? to});

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

///pops the chosen range on Done, null on Cancel / close / barrier (the previous range stays)
class AppDateRangeDialog extends StatefulWidget {
  static Future<DayRange?> show({
    required DayRange initial,
    required String emptyLabel,
  }) => app.dialog.open<DayRange>(
    dialog: AppDateRangeDialog(initial: initial, emptyLabel: emptyLabel),
    barrierColor: const Color(0x7308070c),
  );

  final DayRange initial;

  ///the subtitle with no day picked yet ("Any date")
  final String emptyLabel;

  const AppDateRangeDialog({
    required this.initial,
    required this.emptyLabel,
    super.key,
  });

  @override
  State<AppDateRangeDialog> createState() => _AppDateRangeDialogState();
}

class _AppDateRangeDialogState extends State<AppDateRangeDialog> {
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
                          formatDayRange(_range, widget.emptyLabel),
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
