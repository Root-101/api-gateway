import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Mode { view, edit, confirm }

///the health check add-on of a [route], as in the canvas: LIVE / DOWN, endpoint, interval and
///last result, "Run now", edit in place (with on / off) and remove with a confirmation in place
class HealthCheckBlock extends StatefulWidget {
  final RouteModel route;
  final HealthCheckModel model;

  const HealthCheckBlock({required this.route, required this.model, super.key});

  @override
  State<HealthCheckBlock> createState() => _HealthCheckBlockState();
}

class _HealthCheckBlockState extends State<HealthCheckBlock> {
  final HealthCheckCubit cubit = app.di.find();
  final TextEditingController _path = TextEditingController();
  _Mode _mode = _Mode.view;
  int _interval = 30;
  bool _busy = false;
  bool _checking = false;
  String? _pathError;
  String? _intervalError;

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  void _startEdit() {
    _path.text = widget.model.path;
    setState(() {
      _mode = _Mode.edit;
      _interval = widget.model.intervalSeconds;
      _pathError = null;
      _intervalError = null;
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await cubit.put(
      route: widget.route,
      model: HealthCheckModel(
        //on / off is the slide in the view
        enabled: widget.model.enabled,
        path: _path.text,
        intervalSeconds: _interval,
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
        _pathError = fields['path'];
        _intervalError = fields['interval_seconds'] ?? fields['enabled'];
      }
    });
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    await cubit.delete(route: widget.route);
    if (mounted) setState(() => _busy = false);
  }

  ///true when it was saved (the slide keeps its handle where it was dropped till then)
  Future<bool> _toggle(bool on) async {
    setState(() => _busy = true);
    final error = await cubit.setEnabled(route: widget.route, enabled: on);
    if (mounted) setState(() => _busy = false);
    return error == null;
  }

  Future<void> _run() async {
    setState(() => _checking = true);
    await cubit.runNow(route: widget.route);
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final m = widget.model;
    //the icon keeps the state's color; LIVE / DOWN themselves go at the end of the last check
    final color = !m.enabled || m.up == null
        ? c.label
        : m.up!
        ? c.success
        : c.dangerText;
    return CallbackShortcuts(
      bindings: {
        if (_mode != _Mode.view)
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              setState(() => _mode = _Mode.view),
      },
      child: AnimatedContainer(
        duration: motion(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _mode == _Mode.confirm
                ? c.danger
                : m.down
                ? c.danger.withValues(alpha: 0.5)
                : c.outlineCard,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddonHeader(
              icon: app.assets.icons.general.activity,
              iconColor: color,
              title: intl.health.title,
              info: healthInfo(context),
              showActions: _mode == _Mode.view,
              onEdit: _startEdit,
              onRemove: () => setState(() => _mode = _Mode.confirm),
              extraActions: [
                _checking
                    ? SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(child: SmallSpinner(color: c.label)),
                      )
                    : AppIconButton(
                        icon: app.assets.icons.general.play,
                        tooltip: intl.health.runNow,
                        size: 34,
                        iconSize: 14,
                        onPressed: _run,
                      ),
              ],
            ),
            const SizedBox(height: 8),
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
    final every = intervalText(m.intervalSeconds);
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: c.textTertiary,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
    final style = TextStyle(fontSize: 13, height: 18 / 13, color: c.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          intl.health.endpoint,
          SelectableText(
            m.path,
            style: monoStyle(size: 13, height: 18 / 13, color: c.text),
          ),
        ),
        row(
          intl.health.every,
          Text(
            m.enabled
                ? intl.health.everyValue(time: every)
                : intl.health.offValue(time: every),
            style: style,
          ),
        ),
        row(
          intl.health.lastCheck,
          _checking
              ? Text(
                  intl.health.checking,
                  style: style.copyWith(color: c.textTertiary),
                )
              : Ticking(
                  builder: (context) => Text.rich(
                    TextSpan(
                      text: _lastText(context, m),
                      children: [
                        //"12 s ago · 200 in 18 ms · LIVE", as in the canvas; off, the result is old
                        if (m.enabled && m.checkedAt != null && m.up != null)
                          TextSpan(
                            text: ' · ',
                            children: [
                              TextSpan(
                                text: m.up!
                                    ? intl.health.live
                                    : intl.health.down,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: m.up! ? c.success : c.dangerText,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    style: m.up == false
                        ? style.copyWith(color: c.dangerText)
                        : style,
                  ),
                ),
        ),
        AddonSlideSection(
          title: intl.health.enabled,
          hint: m.enabled
              ? intl.health.hintOn(time: intervalText(m.intervalSeconds))
              : intl.health.hintOff,
          value: m.enabled,
          onLabel: intl.health.slideOn,
          offLabel: intl.health.slideOff,
          color: c.success,
          onColor: const Color(0xff0f3a14),
          onChanged: _toggle,
        ),
      ],
    );
  }

  static String _lastText(BuildContext context, HealthCheckModel m) {
    final intl = context.intl.health;
    final at = m.checkedAt;
    if (at == null) return intl.waiting;
    final seconds = DateTime.now().difference(at).inSeconds;
    final ago = seconds < 10
        ? intl.justNow
        : intl.ago(time: seconds < 60 ? '$seconds s' : durationText(seconds));
    final status = m.status;
    return status == null
        ? intl.noAnswer(ago: ago)
        : intl.answered(ago: ago, status: status, millis: m.millis ?? 0);
  }

  Widget _buildEdit(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );
    //a value set through the api that isn't one of the choices stays selectable
    final intervals = {...HealthCheckModel.intervals, _interval}.toList()
      ..sort();
    final host = widget.route.uri.replaceFirst(RegExp(r'^https?://'), '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(intl.health.endpoint),
        const SizedBox(height: 6),
        TextField(
          controller: _path,
          autofocus: true,
          style: monoStyle(size: 13, color: c.text),
          cursorColor: c.lilac,
          onChanged: (_) => setState(() => _pathError = null),
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            hintText: '/health',
            hintStyle: monoStyle(size: 13, color: c.textTertiary),
            isDense: true,
            filled: true,
            fillColor: c.night,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: border(_pathError != null ? c.danger : c.outline),
            focusedBorder: border(_pathError != null ? c.danger : c.lilac, 2),
          ),
        ),
        const SizedBox(height: 6),
        if (_pathError != null) ...[
          Text(
            _pathError!,
            style: TextStyle(fontSize: 12, color: c.dangerText),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          intl.health.calledOn(host: host),
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: c.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        FieldLabel(intl.health.checkEvery),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.brandBorder,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              for (final (i, seconds) in intervals.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: _intervalOption(seconds)),
              ],
            ],
          ),
        ),
        if (_intervalError != null) ...[
          const SizedBox(height: 6),
          Text(
            _intervalError!,
            style: TextStyle(fontSize: 12, color: c.dangerText),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              label: intl.actions.cancel,
              kind: AppButtonKind.outlined,
              height: 34,
              radius: 10,
              fontSize: 13,
              onPressed: () => setState(() => _mode = _Mode.view),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.panel.save,
              height: 34,
              radius: 10,
              fontSize: 13,
              leading: _busy ? SmallSpinner(color: c.onLilac) : null,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ],
    );
  }

  Widget _intervalOption(int seconds) {
    final c = app.colors;
    final on = seconds == _interval;
    final text = intervalText(seconds).replaceAll(' ', '');
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            _interval = seconds;
            _intervalError = null;
          }),
          child: SizedBox(
            height: 30,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? c.onSelected : c.label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context) {
    final intl = context.intl;
    return AddonRemoveConfirm(
      title: intl.health.removeTitle,
      body: intl.health.removeBody,
      busy: _busy,
      onCancel: () => setState(() => _mode = _Mode.view),
      onRemove: _remove,
    );
  }
}
