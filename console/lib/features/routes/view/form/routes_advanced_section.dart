import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///api validation errors that belong to this section, e.g. `order`, `methods[0].<list element>`, `filters[1].supported`
bool isAdvancedRouteError(String source) =>
    RegExp(r'^(order$|(methods|hosts|headers|filters)\[)').hasMatch(source);

class RouteHeaderFormRow {
  final name = TextEditingController();
  final regexp = TextEditingController();

  void dispose() {
    name.dispose();
    regexp.dispose();
  }
}

class RouteFilterFormRow {
  String name = RouteFilterModel.argCounts.keys.first;

  //both always exist, so switching the filter back doesn't lose what was typed
  final args = [TextEditingController(), TextEditingController()];

  int get argCount => RouteFilterModel.argCounts[name] ?? args.length;

  void dispose() {
    for (final arg in args) {
      arg.dispose();
    }
  }
}

///state of the section: lives in the form so it survives collapsing it and the rebuild after a 422
class RouteAdvancedFormController {
  final order = TextEditingController();
  final Set<String> methods = {};
  final List<TextEditingController> hosts = [];
  final List<RouteHeaderFormRow> headers = [];
  final List<RouteFilterFormRow> filters = [];

  bool get hasValues =>
      order.text.isNotEmpty ||
      hosts.isNotEmpty ||
      headers.isNotEmpty ||
      filters.isNotEmpty;

  void load(RouteAdvancedModel model) {
    order.text = model.order == 0 ? '' : '${model.order}';
    methods.addAll(model.methods);
    hosts.addAll(model.hosts.map((e) => TextEditingController(text: e)));
    headers.addAll(
      model.headers.map(
        (e) => RouteHeaderFormRow()
          ..name.text = e.name
          ..regexp.text = e.regexp ?? '',
      ),
    );
    for (final filter in model.filters) {
      final row = RouteFilterFormRow()..name = filter.name;
      for (var i = 0; i < filter.args.length && i < row.args.length; i++) {
        row.args[i].text = filter.args[i];
      }
      filters.add(row);
    }
  }

  ///rows are sent as they are, in order, so the indexes of the api errors match the rows
  RouteAdvancedModel toModel() => RouteAdvancedModel(
    order: int.tryParse(order.text) ?? 0,
    methods: RouteAdvancedModel.httpMethods.where(methods.contains).toList(),
    hosts: [for (final host in hosts) host.text],
    headers: [
      for (final row in headers)
        RouteHeaderCondition(
          name: row.name.text,
          regexp: row.regexp.text.isEmpty ? null : row.regexp.text,
        ),
    ],
    filters: [
      for (final row in filters)
        RouteFilterModel(
          name: row.name,
          args: [for (final arg in row.args.take(row.argCount)) arg.text],
        ),
    ],
  );

  void dispose() {
    order.dispose();
    for (final host in hosts) {
      host.dispose();
    }
    for (final row in headers) {
      row.dispose();
    }
    for (final row in filters) {
      row.dispose();
    }
  }
}

class RoutesAdvancedSection extends StatelessWidget {
  final RouteAdvancedFormController controller;
  final Map<String, String> errors;
  final bool expanded;
  final VoidCallback onToggle;

  ///the rows changed: the form rebuilds and drops the api errors, whose indexes are no longer valid
  final VoidCallback onChanged;
  final FormFieldValidator<String> requiredValidator;

  const RoutesAdvancedSection({
    required this.controller,
    required this.errors,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.requiredValidator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: app.dimensions.padding.xs),
            child: Row(
              children: [
                Text(
                  app.intl.routes.advancedTitle,
                  style: app.textTheme.titleMedium,
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        //offstage and not removed: the validators of a collapsed section still have to run
        ExcludeFocus(
          excluding: !expanded,
          child: Offstage(offstage: !expanded, child: _buildBody()),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final intl = app.intl.routes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        app.dimensions.padding.s.gap(),
        AppTextInput.textField(
          controller: controller.order,
          errorText: errors['order'],
          label: intl.orderLabel,
          hint: intl.orderHint,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
          validator: (value) => RouteAdvancedModel.isValidOrder(value ?? '')
              ? null
              : app.intl.validations.wholeNumberField,
        ),
        app.dimensions.padding.l.gap(),
        _buildMethods(),
        app.dimensions.padding.l.gap(),
        _buildList(
          label: intl.hostsLabel,
          addLabel: intl.addHost,
          onAdd: () => controller.hosts.add(TextEditingController()),
          rows: [
            for (final (i, host) in controller.hosts.indexed)
              _row(
                key: host,
                onDelete: () => _remove(controller.hosts, host, host.dispose),
                child: AppTextInput.textField(
                  controller: host,
                  errorText: errors['hosts[$i].<list element>'],
                  hint: intl.hostHint,
                  validator: requiredValidator,
                ),
              ),
          ],
        ),
        app.dimensions.padding.l.gap(),
        _buildList(
          label: intl.headersLabel,
          addLabel: intl.addHeader,
          onAdd: () => controller.headers.add(RouteHeaderFormRow()),
          rows: [
            for (final (i, row) in controller.headers.indexed)
              _row(
                key: row,
                onDelete: () => _remove(controller.headers, row, row.dispose),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextInput.textField(
                        controller: row.name,
                        errorText: errors['headers[$i].name'],
                        label: intl.headerNameLabel,
                        hint: intl.headerNameHint,
                        validator: requiredValidator,
                      ),
                    ),
                    app.dimensions.padding.m.gap(),
                    Expanded(
                      child: AppTextInput.textField(
                        controller: row.regexp,
                        errorText:
                            errors['headers[$i].validRegexp'] ??
                            errors['headers[$i].regexp'],
                        label: intl.headerRegexpLabel,
                        hint: intl.headerRegexpHint,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        app.dimensions.padding.l.gap(),
        _buildList(
          label: intl.filtersLabel,
          addLabel: intl.addFilter,
          onAdd: () => controller.filters.add(RouteFilterFormRow()),
          rows: [
            for (final (i, row) in controller.filters.indexed)
              _row(
                key: row,
                onDelete: () => _remove(controller.filters, row, row.dispose),
                child: _buildFilter(i, row),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethods() {
    final error = errors.entries
        .where((e) => e.key.startsWith('methods['))
        .firstOrNull
        ?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(app.intl.routes.methodsLabel),
        app.dimensions.padding.xs.gap(),
        Wrap(
          spacing: app.dimensions.padding.s,
          runSpacing: app.dimensions.padding.xs,
          children: [
            for (final method in RouteAdvancedModel.httpMethods)
              FilterChip(
                label: Text(method),
                selected: controller.methods.contains(method),
                onSelected: (selected) {
                  selected
                      ? controller.methods.add(method)
                      : controller.methods.remove(method);
                  onChanged();
                },
              ),
          ],
        ),
        if (error != null) ...[
          app.dimensions.padding.xs.gap(),
          Text(
            error,
            style: app.textTheme.labelMedium?.copyWith(
              color: app.colors.primary.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilter(int i, RouteFilterFormRow row) {
    final intl = app.intl.routes;
    final style = app.textTheme.titleMedium?.copyWith(
      color: app.colors.neutral.white,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponentTemplate(
          label: intl.filterNameLabel,
          errorText: errors['filters[$i].supported'] ?? errors['filters[$i].name'],
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
            child: DropdownButtonFormField<String>(
              initialValue: row.name,
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
              dropdownColor: app.colors.primary.background1,
              onChanged: (value) {
                if (value != null) row.name = value;
                onChanged();
              },
              items: [
                for (final name in RouteFilterModel.argCounts.keys)
                  DropdownMenuItem(
                    value: name,
                    child: Text(name, style: style),
                  ),
              ],
            ),
          ),
        ),
        app.dimensions.padding.s.gap(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildFilterArg(i, row, 0)),
            if (row.argCount > 1) ...[
              app.dimensions.padding.m.gap(),
              Expanded(child: _buildFilterArg(i, row, 1)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterArg(int i, RouteFilterFormRow row, int arg) {
    final intl = app.intl.routes;
    return AppTextInput.textField(
      controller: row.args[arg],
      errorText:
          errors['filters[$i].args[$arg].<list element>'] ??
          (arg == 0 ? errors['filters[$i].args'] : null),
      label: arg == 0 ? intl.headerNameLabel : intl.filterValueLabel,
      hint: arg == 0 ? intl.filterNameHint : intl.filterValueHint,
      validator: requiredValidator,
    );
  }

  Widget _buildList({
    required String label,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Widget> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        app.dimensions.padding.xs.gap(),
        ...rows,
        TextButton.icon(
          onPressed: () {
            onAdd();
            onChanged();
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text(addLabel),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: app.textTheme.labelMedium?.copyWith(color: app.colors.neutral.grey2),
  );

  ///keyed by the row so removing one from the middle doesn't move state between the others
  Widget _row({
    required Object key,
    required Widget child,
    required VoidCallback onDelete,
  }) {
    return Padding(
      key: ObjectKey(key),
      padding: EdgeInsets.only(bottom: app.dimensions.padding.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          IconButton(
            tooltip: app.intl.actions.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  void _remove<T>(List<T> list, T row, VoidCallback dispose) {
    list.remove(row);
    //after the frame: the removed text field still uses its controller until then
    WidgetsBinding.instance.addPostFrameCallback((_) => dispose());
    onChanged();
  }
}
