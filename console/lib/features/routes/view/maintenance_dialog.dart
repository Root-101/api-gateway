import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///turns maintenance on or off, of a [route] or (null) of the whole gateway, with its message and return time
class MaintenanceDialog extends StatefulWidget {
  final RouteModel? route;

  const MaintenanceDialog({this.route, super.key});

  static Future<void> show({RouteModel? route}) =>
      app.dialog.open(dialog: MaintenanceDialog(route: route));

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  final MaintenanceCubit cubit = app.di.find();
  final TextEditingController _message = TextEditingController();
  late bool _enabled;
  DateTime? _retryAfter;

  bool get _global => widget.route == null;

  bool get _tooLong => _message.text.length > MaintenanceModel.maxMessage;

  @override
  void initState() {
    super.initState();
    final current = _global ? cubit.global : widget.route!.maintenance;
    //opening it is almost always to turn it on
    _enabled = current?.enabled ?? true;
    _message.text = current?.message ?? '';
    _retryAfter = current?.retryAfter?.toLocal();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickRetryAfter() async {
    final now = DateTime.now();
    final initial = _retryAfter == null || _retryAfter!.isBefore(now)
        ? now.add(const Duration(hours: 1))
        : _retryAfter!;
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.startOfDay,
      lastDate: now.add(const Duration(days: 366)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(
      () => _retryAfter = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _save() {
    if (_tooLong) return;
    final message = _message.text.trim();
    cubit.save(
      route: widget.route,
      model: MaintenanceModel(
        enabled: _enabled,
        message: message.isEmpty ? null : message,
        retryAfter: _retryAfter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = context.intl;
    final route = widget.route;
    return BlocListener<MaintenanceCubit, MaintenanceState>(
      bloc: cubit,
      //the toast and the error are shown by the shell, behind it
      listener: (context, state) {
        if (state is MaintenanceSaveOkState) Navigator.of(context).pop();
      },
      child: DialogTemplate(
        width: 560,
        alignment: Alignment.center,
        title: _global
            ? intl.maintenance.globalTitle
            : intl.maintenance.routeTitle,
        subtitle: _global
            ? intl.maintenance.globalSubtitle
            : '${route!.name} · ${route.path}',
        subtitleMono: !_global,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSwitch(context),
            if (!_global && _enabled && cubit.globalOn) ...[
              const SizedBox(height: 18),
              _buildBothOn(context),
            ],
            const SizedBox(height: 18),
            _buildMessage(context),
            const SizedBox(height: 18),
            _buildRetryAfter(context),
            const SizedBox(height: 18),
            _buildPreview(context),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              label: intl.actions.cancel,
              kind: AppButtonKind.outlined,
              height: 44,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: !_enabled
                  ? intl.maintenance.saveOff
                  : _global
                  ? intl.maintenance.turnOnAll
                  : intl.maintenance.save,
              kind: _enabled
                  ? AppButtonKind.maintenance
                  : AppButtonKind.primary,
              height: 44,
              onPressed: _tooLong ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    const off = Color(0xff938f99);
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _enabled ? c.maintenance.withValues(alpha: 0.08) : c.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _enabled ? c.maintenance.withValues(alpha: 0.45) : c.raised,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intl.maintenance.inMaintenance,
                    style: TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w500,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !_enabled
                        ? intl.maintenance.offHint
                        : _global
                        ? intl.maintenance.globalOnHint
                        : intl.maintenance.routeOnHint,
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Switch(
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              activeTrackColor: c.maintenance,
              activeThumbColor: c.onMaintenance,
              inactiveTrackColor: c.toast,
              inactiveThumbColor: off,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? c.maintenance : off,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBothOn(BuildContext context) {
    final c = app.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.raised),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: app.assets.icons.general.info.build(
              size: 18,
              color: c.lilac,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.intl.maintenance.bothOn,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: c.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final tooLong = _tooLong;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    const textStyle = TextStyle(fontSize: 15, height: 22 / 15);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FieldLabel(intl.maintenance.message),
            Text(
              intl.maintenance.count(
                count: _message.text.length,
                max: MaintenanceModel.maxMessage,
              ),
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: tooLong ? c.dangerText : c.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        //no length limit: the counter turns red instead of cutting a paste
        TextField(
          controller: _message,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          style: textStyle.copyWith(color: c.text),
          cursorColor: c.lilac,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: intl.maintenance.messageHint,
            hintStyle: textStyle.copyWith(color: c.textTertiary),
            hintMaxLines: 2,
            filled: true,
            fillColor: c.field,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: border(tooLong ? c.danger : c.outline),
            focusedBorder: border(tooLong ? c.danger : c.lilac, 2),
          ),
        ),
        if (tooLong) ...[
          const SizedBox(height: 6),
          Text(
            intl.maintenance.tooLong(max: MaintenanceModel.maxMessage),
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: c.dangerText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRetryAfter(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final retry = _retryAfter;
    final seconds = MaintenanceModel.retrySecondsOf(retry);
    final passed = retry != null && seconds == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: '${intl.maintenance.backAt} ',
            children: [
              TextSpan(
                text: intl.maintenance.optional,
                style: TextStyle(
                  color: c.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: c.label,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Material(
                color: c.field,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickRetryAfter,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            retry == null
                                ? intl.maintenance.pickTime
                                : '${app.dateFormatter.logsTimeS.format(retry)}, '
                                      '${app.dateFormatter.clock.format(retry)}',
                            style: monoStyle(
                              size: 14,
                              color: retry == null ? c.textTertiary : c.text,
                            ),
                          ),
                        ),
                        app.assets.icons.general.calendar.build(
                          size: 18,
                          color: c.label,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (retry != null) ...[
              const SizedBox(width: 8),
              AppButton(
                label: intl.maintenance.clear,
                kind: AppButtonKind.outlined,
                height: 48,
                onPressed: () => setState(() => _retryAfter = null),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          retry == null
              ? intl.maintenance.noTime
              : passed
              ? intl.maintenance.timePassed
              : intl.maintenance.retryAfter(
                  seconds: seconds,
                  left: durationText(seconds),
                ),
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: passed ? c.maintenance : c.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final seconds = MaintenanceModel.retrySecondsOf(_retryAfter);
    final message = _message.text.trim();
    return Semantics(
      container: true,
      child: Opacity(
        opacity: _enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.night,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.outlineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptionText(
                _enabled
                    ? intl.maintenance.callersGet
                    : intl.maintenance.callersWouldGet,
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '503 ',
                      style: TextStyle(color: c.softRed),
                    ),
                    TextSpan(text: intl.maintenance.serviceUnavailable),
                  ],
                ),
                style: monoStyle(size: 13, height: 20 / 13, color: c.text),
              ),
              if (seconds > 0)
                Text(
                  'Retry-After: $seconds',
                  style: monoStyle(
                    size: 12,
                    height: 18 / 12,
                    color: c.textSecondary,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                message.isEmpty ? intl.maintenance.defaultMessage : message,
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: message.isEmpty ? c.textTertiary : c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
