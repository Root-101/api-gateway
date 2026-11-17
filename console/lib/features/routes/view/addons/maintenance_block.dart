import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/addons/slide_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Mode { view, edit, confirm }

///the maintenance add-on of a [route], or of the gateway when null: its message and return time,
///the slide to turn it on or off, edit in place and (routes only) remove with a confirmation in place
class MaintenanceBlock extends StatefulWidget {
  final RouteModel? route;
  final MaintenanceModel model;

  ///the gateway's maintenance is on: a route's can't be switched until it's off
  final bool locked;

  const MaintenanceBlock({
    required this.model,
    this.route,
    this.locked = false,
    super.key,
  });

  @override
  State<MaintenanceBlock> createState() => _MaintenanceBlockState();
}

class _MaintenanceBlockState extends State<MaintenanceBlock> {
  final MaintenanceCubit cubit = app.di.find();
  final TextEditingController _message = TextEditingController();
  _Mode _mode = _Mode.view;
  DateTime? _retryAfter;
  bool _busy = false;
  String? _messageError;
  String? _retryError;

  bool get _gateway => widget.route == null;

  bool get _tooLong => _message.text.length > MaintenanceModel.maxMessage;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _startEdit() {
    _message.text = widget.model.message ?? '';
    _retryAfter = widget.model.retryAfter?.toLocal();
    setState(() {
      _mode = _Mode.edit;
      _messageError = null;
      _retryError = null;
    });
  }

  Future<void> _save() async {
    if (_tooLong || _busy) return;
    setState(() => _busy = true);
    final error = await cubit.put(
      route: widget.route,
      model: MaintenanceModel(
        enabled: widget.model.enabled,
        message: _message.text,
        retryAfter: _retryAfter,
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _mode = _Mode.view;
      } else if (error.data is List<ValidationError>) {
        final fields = (error.data as List<ValidationError>)
            .asFailedValidations();
        _messageError = fields['message'];
        _retryError = fields['retry_after'];
      }
    });
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    await cubit.delete(route: widget.route!);
    if (mounted) setState(() => _busy = false);
  }

  void _toggle(bool on) => cubit.setEnabled(route: widget.route, enabled: on);

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final on = widget.model.enabled && !widget.locked;
    return CallbackShortcuts(
      bindings: {
        if (_mode == _Mode.edit)
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              setState(() => _mode = _Mode.view),
        if (_mode == _Mode.confirm)
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              setState(() => _mode = _Mode.view),
      },
      child: AnimatedContainer(
        duration: motion(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 16),
        decoration: BoxDecoration(
          color: on ? c.maintenance.withValues(alpha: 0.06) : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on || _mode != _Mode.view
                ? c.maintenance.withValues(alpha: 0.45)
                : c.outlineCard,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                app.assets.icons.general.wrench.build(
                  size: 17,
                  color: on ? c.maintenance : c.label,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    intl.panel.maintenance,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
                if (_mode == _Mode.view) ...[
                  AppIconButton(
                    icon: app.assets.icons.actions.edit,
                    tooltip: intl.panel.edit,
                    size: 34,
                    iconSize: 16,
                    onPressed: _startEdit,
                  ),
                  if (!_gateway)
                    AppIconButton(
                      icon: app.assets.icons.actions.delete,
                      tooltip: intl.panel.remove,
                      size: 34,
                      iconSize: 16,
                      hoverColor: c.softRed,
                      onPressed: () => setState(() => _mode = _Mode.confirm),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: switch (_mode) {
                _Mode.view => _buildView(context),
                _Mode.edit => _buildEdit(context),
                _Mode.confirm => _buildConfirm(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final m = widget.model;
    final on = m.enabled && !widget.locked;
    final status = widget.locked
        ? intl.panel.locked
        : m.enabled
        ? (_gateway ? intl.panel.onGateway : intl.panel.onRoute)
        : (_gateway ? intl.panel.offGateway : intl.panel.offRoute);
    final duration = m.onFor ?? m.lastWindow;
    final durationLabel = duration == null
        ? null
        : m.onFor != null
        ? intl.panel.onFor(time: durationText(duration.inSeconds))
        : intl.panel.lastWindow(time: durationText(duration.inSeconds));
    final retry = m.retryAfter?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          status,
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            color: on ? c.maintenance : c.textTertiary,
          ),
        ),
        if (durationLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            durationLabel,
            style: TextStyle(fontSize: 12, color: c.textTertiary),
          ),
        ],
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: c.outlineCard,
        ),
        CaptionText(intl.panel.message503, color: c.maintenance),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: m.shownMessage(intl.maintenance.defaultMessage),
            children: [
              if (!m.hasOwnMessage)
                TextSpan(
                  text: '  ${intl.panel.defaultTag}',
                  style: TextStyle(fontSize: 12, color: c.textTertiary),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: m.hasOwnMessage ? c.text : c.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          retry == null
              ? intl.panel.noReturn
              : intl.panel.backAround(
                  date: app.dateFormatter.dayTime.format(retry),
                ),
          style: TextStyle(fontSize: 12, color: c.label),
        ),
        const SizedBox(height: 14),
        SlideSwitch(
          value: m.enabled,
          onLabel: intl.panel.slideOn,
          offLabel: intl.panel.slideOff,
          hint: intl.panel.slideHint,
          lockedLabel: intl.panel.locked,
          onChanged: widget.locked ? null : _toggle,
        ),
        if (widget.locked) ...[
          const SizedBox(height: 8),
          Text(
            intl.panel.lockedHint,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: c.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEdit(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final tooLong = _tooLong;
    final fallback =
        widget.model.defaultMessage ?? intl.maintenance.defaultMessage;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    final messageError = tooLong
        ? intl.panel.tooLong(max: MaintenanceModel.maxMessage)
        : _messageError;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FieldLabel(intl.panel.messageLabel),
              Text(
                intl.panel.count(
                  count: _message.text.length,
                  max: MaintenanceModel.maxMessage,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: tooLong ? c.dangerText : c.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          //no length limit: the counter turns red instead of cutting a paste
          TextField(
            controller: _message,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            style: TextStyle(fontSize: 14, height: 20 / 14, color: c.text),
            cursorColor: c.lilac,
            onChanged: (_) => setState(() => _messageError = null),
            decoration: InputDecoration(
              hintText: intl.panel.messageHint(text: fallback),
              hintMaxLines: 3,
              hintStyle: TextStyle(fontSize: 14, color: c.textTertiary),
              filled: true,
              fillColor: c.field,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: border(
                messageError != null ? c.danger : c.outline,
              ),
              focusedBorder: border(
                messageError != null ? c.danger : c.lilac,
                2,
              ),
            ),
          ),
          if (messageError != null) ...[
            const SizedBox(height: 6),
            Text(
              messageError,
              style: TextStyle(fontSize: 12, color: c.dangerText),
            ),
          ],
          const SizedBox(height: 14),
          FieldLabel(intl.panel.backLabel),
          const SizedBox(height: 6),
          RetryAfterField(
            value: _retryAfter,
            hasError: _retryError != null,
            onChanged: (value) => setState(() {
              _retryAfter = value;
              _retryError = null;
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _retryError ?? intl.panel.backHint,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: _retryError != null ? c.dangerText : c.textTertiary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: intl.actions.cancel,
                kind: AppButtonKind.outlined,
                height: 40,
                onPressed: () => setState(() => _mode = _Mode.view),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: intl.panel.save,
                height: 40,
                leading: _busy ? SmallSpinner(color: c.onLilac) : null,
                onPressed: tooLong || _busy ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Text(
          intl.panel.removeTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          intl.panel.removeBody,
          style: TextStyle(fontSize: 13, height: 18 / 13, color: c.label),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              label: intl.actions.cancel,
              kind: AppButtonKind.outlined,
              height: 40,
              autofocus: true, //so Enter doesn't remove by accident
              onPressed: () => setState(() => _mode = _Mode.view),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.panel.remove,
              icon: app.assets.icons.actions.delete,
              kind: AppButtonKind.softDanger,
              height: 40,
              onPressed: _busy ? null : _remove,
            ),
          ],
        ),
      ],
    );
  }
}

///the return time: a date and a 24 h time from the pickers, with Clear
class RetryAfterField extends StatelessWidget {
  final DateTime? value;
  final bool hasError;
  final ValueChanged<DateTime?> onChanged;

  const RetryAfterField({
    required this.value,
    required this.onChanged,
    this.hasError = false,
    super.key,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value == null || value!.isBefore(now)
        ? now.add(const Duration(hours: 1))
        : value!;
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.startOfDay,
      lastDate: now.add(const Duration(days: 366)),
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    onChanged(DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final v = value;
    return Row(
      children: [
        Expanded(
          child: Material(
            color: c.field,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: hasError ? c.danger : c.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _pick(context),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        v == null
                            ? intl.panel.pickTime
                            : '${app.dateFormatter.logsTimeS.format(v)}, '
                                  '${app.dateFormatter.clock.format(v)}',
                        style: monoStyle(
                          size: 13,
                          color: v == null ? c.textTertiary : c.text,
                        ),
                      ),
                    ),
                    app.assets.icons.general.calendar.build(
                      size: 17,
                      color: c.label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (v != null) ...[
          const SizedBox(width: 8),
          AppButton(
            label: intl.panel.clear,
            kind: AppButtonKind.outlined,
            height: 44,
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }
}
