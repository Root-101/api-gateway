import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FilterCallback =
    Future Function({
      int? responseCode,
      String? httpMethod,
      RouteLogModel? route,
      DateTime? fromDate,
      DateTime? toDate,
    });

const List<String> httpMethods = [
  'GET',
  'HEAD',
  'POST',
  'PUT',
  'DELETE',
  'CONNECT',
  'OPTIONS',
  'TRACE',
];

class LogsFilterDialog extends StatefulWidget {
  static void show({
    required LogsSearchFilters filters,
    required FilterCallback callback,
    required List<RouteLogModel> routes,
  }) {
    DialogTemplate.open(
      title: app.intl.filter,
      w: 500,
      child: LogsFilterDialog(
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
  DateTime? fromDate;
  DateTime? toDate;

  RouteLogModel? route;

  String? httpMethod;

  final TextEditingController responseCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    responseCode.text = widget.filters.responseCode?.toString() ?? '';
    httpMethod = widget.filters.httpMethod;
    route = widget.filters.route;
    fromDate = widget.filters.date?.fromDate;
    toDate = widget.filters.date?.toDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.colors.neutral.transparent,
      body: Padding(
        padding: EdgeInsets.all(app.dimensions.padding.l),
        child: Column(
          children: [
            AppTextInput.textField(
              controller: responseCode,
              label: app.intl.filterHttpStatusLabel,
              hint: app.intl.filterHttpStatusHint,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            app.dimensions.padding.l.gap(),
            _buildHttpMethodSelector(),
            app.dimensions.padding.l.gap(),
            _buildRouteSelector(),
            app.dimensions.padding.l.gap(),
            _buildDateRangeSelector(),
            app.dimensions.padding.xl.gap(),
            Divider(color: app.colors.neutral.grey3),
            app.dimensions.padding.s.gap(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    responseCode.clear();
                    httpMethod = null;
                    route = null;
                    fromDate = null;
                    toDate = null;
                  });
                },
                child: Text(
                  app.intl.clearFilters,
                  style: app.textTheme.titleSmall?.copyWith(
                    color: app.colors.neutral.white,
                  ),
                ),
              ),
            ),
            120.gap(),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.all(app.dimensions.padding.l),
        child: PrimaryButton.primary(
          onPressed: () {
            widget.callback(
              responseCode: int.tryParse(responseCode.text),
              httpMethod: httpMethod,
              route: route,
              fromDate: fromDate,
              toDate: toDate,
            );
          },
          color: app.colors.primary.purple.brighten(0.15),
          title: app.intl.applyFilters,
        ),
      ),
    );
  }

  Widget _buildHttpMethodSelector() {
    TextStyle? style = app.textTheme.titleMedium?.copyWith(
      color: app.colors.neutral.white,
    );
    return FormComponentTemplate(
      label: app.intl.filterMethodLabel,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
        child: DropdownButtonFormField<String>(
          initialValue: httpMethod,
          hint: Text(
            app.intl.filterMethodHint,
            style: app.textTheme.bodyMedium!.copyWith(
              color: app.colors.neutral.grey3,
            ),
          ),
          style: style,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          iconSize: 18,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          borderRadius: BorderRadius.circular(12),
          onChanged: (String? newMethod) {
            setState(() {
              if (newMethod == httpMethod) {
                httpMethod = null;
              } else {
                httpMethod = newMethod;
              }
            });
          },
          dropdownColor: app.colors.primary.background1,
          items: httpMethods.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: style),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRouteSelector() {
    TextStyle? style1 = app.textTheme.titleMedium?.copyWith(
      color: app.colors.neutral.white,
      fontSize: 18.0,
    );
    TextStyle? style2 = app.textTheme.bodySmall?.copyWith(
      color: app.colors.neutral.grey3,
    );
    return FormComponentTemplate(
      label: app.intl.filterRouteLabel,
      height: 64,
      child: DropdownButtonFormField<RouteLogModel>(
        initialValue: route,
        hint: Text(
          app.intl.filterRouteHint,
          style: app.textTheme.bodyMedium!.copyWith(
            color: app.colors.neutral.grey3,
          ),
        ),
        style: style1,
        isDense: false,
        itemHeight: 60,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.only(left: app.dimensions.padding.l),
        ),
        iconSize: 18,
        icon: Padding(
          padding: EdgeInsets.only(right: app.dimensions.padding.l),
          child: const Icon(Icons.arrow_drop_down, size: 16),
        ),
        borderRadius: BorderRadius.circular(12),
        onChanged: (RouteLogModel? newRoute) {
          setState(() {
            if (newRoute == route) {
              route = null;
            } else {
              route = newRoute;
            }
          });
        },
        dropdownColor: app.colors.primary.background1,
        items: widget.routes.map<DropdownMenuItem<RouteLogModel>>((
          RouteLogModel value,
        ) {
          return DropdownMenuItem<RouteLogModel>(
            value: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.routeName, style: style1),
                Text(value.routePath, style: style2),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    Widget buildDatePicker({
      required DateTime? selectedDate,
      required String label,
      required Function(DateTime? selectDate) onSelected,
    }) {
      return Builder(
        builder: (context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  DateTime? selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    initialDate: selectedDate,
                  );
                  onSelected(selected);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: FormComponentTemplate(
                    height: 50,
                    label: label,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: app.dimensions.padding.l,
                      ),
                      child: Text(
                        selectedDate == null
                            ? app.intl.filterDateHint
                            : app.dateFormatter.logsTimeS.format(selectedDate),
                        style: app.textTheme.bodyMedium!.copyWith(
                          color: selectedDate == null
                              ? app.colors.neutral.grey3
                              : app.colors.neutral.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildDatePicker(
            selectedDate: fromDate,
            label: app.intl.filterFromDateLabel,
            onSelected: (selectDate) {
              setState(() {
                if (selectDate == null ||
                    (fromDate != null && fromDate!.isSameDay(selectDate))) {
                  fromDate = null;
                } else {
                  fromDate = selectDate;
                }
              });
            },
          ),
        ),
        app.dimensions.padding.m.gap(),
        Expanded(
          child: buildDatePicker(
            selectedDate: toDate,
            label: app.intl.filterToDateLabel,
            onSelected: (selectDate) {
              setState(() {
                if (selectDate == null ||
                    (toDate != null && toDate!.isSameDay(selectDate))) {
                  toDate = null;
                } else {
                  toDate = selectDate;
                }
              });
            },
          ),
        ),
      ],
    );
  }
}
