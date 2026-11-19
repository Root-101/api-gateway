import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Mode { view, edit, confirm }

///the rate limit add-on of a [route], or of the gateway when null, as in the canvas: the limit
///per client IP and the burst, a switch to turn it on or off, edit in place and
///remove with a confirmation in place
class RateLimitBlock extends StatefulWidget {
  final RouteModel? route;
  final RateLimitModel model;

  const RateLimitBlock({required this.model, this.route, super.key});

  @override
  State<RateLimitBlock> createState() => _RateLimitBlockState();
}

class _RateLimitBlockState extends State<RateLimitBlock> {
  final RateLimitCubit cubit = app.di.find();
  final TextEditingController _limit = TextEditingController();
  final TextEditingController _burst = TextEditingController();
  _Mode _mode = _Mode.view;
  String _period = 'minute';
  bool _busy = false;
  Map<String, String> _errors = {};

  bool get _gateway => widget.route == null;

  @override
  void dispose() {
    _limit.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _startEdit() {
    _limit.text = '${widget.model.limit}';
    _burst.text = widget.model.burst?.toString() ?? '';
    setState(() {
      _mode = _Mode.edit;
      _period = widget.model.period;
      _errors = {};
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final burst = _burst.text.trim();
    final error = await cubit.put(
      route: widget.route,
      model: RateLimitModel(
        enabled: widget.model.enabled,
        //not a number: 0, so the gateway says what's wrong in its own words
        limit: int.tryParse(_limit.text.trim()) ?? 0,
        period: _period,
        burst: burst.isEmpty ? null : int.tryParse(burst) ?? 0,
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _mode = _Mode.view;
      } else if (error.data is List<ValidationError>) {
        _errors = (error.data as List<ValidationError>).asFailedValidations();
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

  String _periodText(BuildContext context, String period) {
    final intl = context.intl.rate;
    return switch (period) {
      'second' => intl.second,
      'hour' => intl.hour,
      _ => intl.minute,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final m = widget.model;
    final color = m.enabled ? c.info : c.label;
    return CallbackShortcuts(
      bindings: {
        if (_mode != _Mode.view)
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              setState(() => _mode = _Mode.view),
      },
      child: AnimatedContainer(
        duration: motion(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _mode == _Mode.confirm ? c.danger : c.outlineCard,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddonHeader(
              icon: app.assets.icons.general.gauge,
              iconColor: color,
              title: intl.rate.title,
              info: rateInfo(context, gateway: _gateway),
              showActions: _mode == _Mode.view,
              onEdit: _startEdit,
              onRemove: () => setState(() => _mode = _Mode.confirm),
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
    final intl = context.intl.rate;
    final m = widget.model;
    final period = _periodText(context, m.period);
    final style = TextStyle(fontSize: 13, height: 18 / 13, color: c.text);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: style.copyWith(color: c.textTertiary)),
          ),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          intl.limit,
          _gateway
              ? intl.limitValueGateway(limit: m.limit, period: period)
              : intl.limitValue(limit: m.limit, period: period),
        ),
        row(
          intl.burst,
          m.burst == null ? intl.burstSame : intl.burstValue(burst: m.burst!),
        ),
        row(intl.overLimit, intl.tooMany),
        _switchRow(value: m.enabled),
      ],
    );
  }

  Widget _switchRow({required bool value}) {
    final c = app.colors;
    final intl = context.intl.rate;
    return AddonSlideSection(
      title: intl.enabled,
      hint: value ? intl.hintOn : intl.hintOff,
      value: value,
      onLabel: intl.slideOn,
      offLabel: intl.slideOff,
      color: c.info,
      onColor: const Color(0xff0b2b45),
      onChanged: _toggle,
    );
  }

  Widget _buildEdit(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );
    Widget field(
      String label,
      String key,
      TextEditingController controller,
      String hint, {
      bool autofocus = false,
    }) {
      final error = _errors[key];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 14, color: c.text),
            cursorColor: c.lilac,
            onChanged: (_) => setState(() => _errors.remove(key)),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: c.textTertiary),
              isDense: true,
              filled: true,
              fillColor: c.night,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: border(error != null ? c.danger : c.outline),
              focusedBorder: border(error != null ? c.danger : c.lilac, 2),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(error, style: TextStyle(fontSize: 12, color: c.dangerText)),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: field(
                intl.rate.requests,
                'limit',
                _limit,
                '60',
                autofocus: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: field(
                intl.rate.burst,
                'burst',
                _burst,
                intl.rate.burstPlaceholder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FieldLabel(intl.rate.per),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.brandBorder,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              for (final (i, period) in RateLimitModel.periods.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: _periodOption(context, period)),
              ],
            ],
          ),
        ),
        if (_errors['period'] ?? _errors['enabled'] case final error?) ...[
          const SizedBox(height: 6),
          Text(error, style: TextStyle(fontSize: 12, color: c.dangerText)),
        ],
        const SizedBox(height: 8),
        Text(
          intl.rate.resetHint,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: c.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
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

  Widget _periodOption(BuildContext context, String period) {
    final c = app.colors;
    final on = period == _period;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            _period = period;
            _errors.remove('period');
          }),
          child: SizedBox(
            height: 30,
            child: Center(
              child: Text(
                _periodText(context, period),
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
      title: intl.rate.removeTitle,
      body: intl.rate.removeBody,
      busy: _busy,
      onCancel: () => setState(() => _mode = _Mode.view),
      onRemove: _remove,
    );
  }
}
