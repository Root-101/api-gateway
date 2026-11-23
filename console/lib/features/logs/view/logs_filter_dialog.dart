import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

typedef FilterCallback = void Function({
  String? responseCode,
  String? httpMethod,
  RouteLogModel? route,
  DateTime? fromDate,
  DateTime? toDate,
});

const List<String> httpMethods = [
  'GET',
  'POST',
  'PUT',
  'PATCH',
  'DELETE',
  'HEAD',
  'OPTIONS',
];

class LogsFilterDialogNavigator {
  void open({
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
}

class LogsFilterDialog extends StatefulWidget {
  static final LogsFilterDialogNavigator navigator =
      LogsFilterDialogNavigator();

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
    final result = await AppDateRangeDialog.show(
      initial: _range,
      emptyLabel: context.intl.logFilters.anyDate,
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
          fillColor: selected ? c.selected : app.colors.fieldDeep,
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
