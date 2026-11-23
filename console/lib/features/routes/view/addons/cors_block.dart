import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Mode { view, edit, confirm }

///the CORS add-on of a [route], or of the gateway when null: its allowed origins and (routes
///only) credentials, edited in place. The gateway's has no switch and no remove: it's always on
class CorsBlock extends StatefulWidget {
  final RouteModel? route;
  final CorsModel model;

  const CorsBlock({required this.model, this.route, super.key});

  @override
  State<CorsBlock> createState() => _CorsBlockState();
}

class _CorsBlockState extends State<CorsBlock> {
  final CorsCubit cubit = app.di.find();
  final TextEditingController _input = TextEditingController();
  _Mode _mode = _Mode.view;
  List<String> _origins = [];
  bool _credentials = false;
  bool _busy = false;

  ///422 errors by field (`allowed_origins`, `allowed_origins[1]`...)
  Map<String, String> _errors = {};

  ///a 400 rule (lockout, credentials...): only a message
  String? _formError;

  bool get _gateway => widget.route == null;

  bool get _allowsAll => _origins.any(corsAllowsAnySite);

  ///where this console runs (`http://localhost:3000`); null off the web
  static final String? _consoleOrigin = () {
    try {
      return Uri.base.origin;
    } catch (_) {
      return null;
    }
  }();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _startEdit() {
    _input.clear();
    setState(() {
      _mode = _Mode.edit;
      _origins = List.of(widget.model.allowedOrigins);
      _credentials = widget.model.allowCredentials;
      _errors = {};
      _formError = null;
    });
  }

  ///the typed origin becomes a chip (no duplicates); the api checks its shape
  ///the typed origin becomes a chip once its shape is right (Enter, or Save with it still typed);
  ///false when it isn't: it stays in the field with the error under it
  bool _addTyped() {
    final origin = _input.text.trim();
    if (!corsOriginValid(origin)) {
      setState(() {
        _errors = {
          'allowed_origins': context.intl.cors.invalidOrigin(origin: origin),
        };
      });
      return false;
    }
    _input.clear();
    if (!_origins.contains(origin)) {
      setState(() {
        _origins.add(origin);
        _clearErrors();
      });
    }
    return true;
  }

  void _removeAt(int i) => setState(() {
    _origins.removeAt(i);
    //the indexes of the errors no longer match
    _clearErrors();
  });

  void _clearErrors() {
    _errors = {};
    _formError = null;
  }

  Future<void> _save() async {
    //what's still typed counts, as if Enter was pressed
    if (_input.text.trim().isNotEmpty && !_addTyped()) return;
    if (_busy || _origins.isEmpty) return;
    setState(() => _busy = true);
    final error = await cubit.put(
      route: widget.route,
      model: CorsModel(
        enabled: widget.model.enabled,
        allowedOrigins: _origins,
        allowCredentials: !_gateway && _credentials && !_allowsAll,
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _mode = _Mode.view;
      } else if (error.data is List<ValidationError>) {
        _errors = (error.data as List<ValidationError>).asFailedValidations();
      } else {
        _formError = error.message;
      }
    });
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    await cubit.delete(route: widget.route!);
    if (mounted) setState(() => _busy = false);
  }

  ///true when it was saved (the slide keeps its handle where it was dropped till then)
  Future<bool> _toggle(bool on) async {
    setState(() => _busy = true);
    final error = await cubit.setEnabled(route: widget.route!, enabled: on);
    if (mounted) setState(() => _busy = false);
    return error == null;
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final m = widget.model;
    final color = m.enabled ? c.lilac : c.label;
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
              icon: app.assets.icons.general.globe,
              iconColor: color,
              title: intl.cors.title,
              info: corsInfo(context, gateway: _gateway),
              showActions: _mode == _Mode.view,
              onEdit: _startEdit,
              onRemove: _gateway
                  ? null
                  : () => setState(() => _mode = _Mode.confirm),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: switch (_mode) {
                _Mode.view => _buildView(context),
                _Mode.edit => _buildEdit(context),
                _Mode.confirm => AddonRemoveConfirm(
                  title: intl.cors.removeTitle,
                  body: intl.cors.removeBody,
                  busy: _busy,
                  onCancel: () => setState(() => _mode = _Mode.view),
                  onRemove: _remove,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context) {
    final c = app.colors;
    final intl = context.intl.cors;
    final m = widget.model;
    final style = TextStyle(fontSize: 13, height: 18 / 13, color: c.text);
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: style.copyWith(color: c.textTertiary)),
          ),
          Expanded(child: value),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          intl.origins,
          SelectionArea(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final o in m.allowedOrigins) _OriginChip(o)],
            ),
          ),
        ),
        row(
          intl.credentials,
          Text(
            _gateway
                ? intl.credentialsGateway
                : m.allowCredentials
                ? intl.credentialsYes
                : intl.credentialsNo,
            style: style,
          ),
        ),
        if (_gateway)
          Text(
            intl.usedByRoutes,
            style: TextStyle(fontSize: 12, color: c.textTertiary),
          )
        else
          _switchRow(value: m.enabled),
      ],
    );
  }

  Widget _switchRow({required bool value}) {
    final c = app.colors;
    final intl = context.intl.cors;
    return AddonSlideSection(
      title: intl.enabled,
      hint: value ? intl.hintOn : intl.hintOff,
      value: value,
      onLabel: intl.slideOn,
      offLabel: intl.slideOff,
      color: c.lilac,
      onColor: c.onLilac,
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
    final listError = _errors['allowed_origins'];
    //a bad pattern names its index: `allowed_origins[1]`
    final chipErrors = [
      for (final (i, o) in _origins.indexed)
        if (_errors['allowed_origins[$i]'] case final e?) '$o: $e',
    ];
    final console = _consoleOrigin;
    final lockout =
        _gateway &&
        console != null &&
        _origins.isNotEmpty &&
        !corsAllows(_origins, console);
    Widget error(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: c.dangerText)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(intl.cors.originsLabel),
        const SizedBox(height: 6),
        if (_origins.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, o) in _origins.indexed)
                _OriginChip(
                  o,
                  error: _errors.containsKey('allowed_origins[$i]'),
                  onRemove: () => _removeAt(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        //rebuilt as it's typed in: the clear button shows only with text
        ListenableBuilder(
          listenable: _input,
          builder: (context, _) => TextField(
            controller: _input,
            autofocus: true,
            style: monoStyle(size: 13, color: c.text),
            cursorColor: c.lilac,
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) _addTyped();
            },
            onChanged: (_) {
              if (_errors.isNotEmpty) setState(_clearErrors);
            },
            decoration: InputDecoration(
              hintText: intl.cors.originsPlaceholder,
              hintStyle: TextStyle(fontSize: 13, color: c.textTertiary),
              isDense: true,
              filled: true,
              fillColor: c.night,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: border(listError != null ? c.danger : c.outline),
              focusedBorder: border(listError != null ? c.danger : c.lilac, 2),
              suffixIcon: _input.text.isEmpty
                  ? null
                  : AppIconButton(
                      icon: app.assets.icons.actions.close,
                      tooltip: intl.cors.clear,
                      size: 28,
                      iconSize: 14,
                      onPressed: () {
                        _input.clear();
                        if (_errors.isNotEmpty) setState(_clearErrors);
                      },
                    ),
            ),
          ),
        ),
        if (listError != null) error(listError),
        for (final e in chipErrors) error(e),
        const SizedBox(height: 6),
        Text(
          intl.cors.originsHint,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: c.textTertiary,
          ),
        ),
        if (!_gateway) ...[
          const SizedBox(height: 10),
          _credentialsRow(context),
        ],
        if (lockout) ...[
          const SizedBox(height: 10),
          _Warning(intl.cors.lockout(origin: console)),
        ],
        if (_formError case final text?) error(text),
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
            ListenableBuilder(
              listenable: _input,
              builder: (context, _) => AppButton(
                label: intl.panel.save,
                height: 34,
                radius: 10,
                fontSize: 13,
                leading: _busy ? SmallSpinner(color: c.onLilac) : null,
                onPressed:
                    _busy || (_origins.isEmpty && _input.text.trim().isEmpty)
                    ? null
                    : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }

  ///off (and not sent) while an origin lets any site in: the api rejects that pair
  Widget _credentialsRow(BuildContext context) {
    final c = app.colors;
    final intl = context.intl.cors;
    final blocked = _allowsAll;
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intl.credentialsSwitch,
                  style: TextStyle(
                    fontSize: 13,
                    color: blocked ? c.textTertiary : c.text,
                  ),
                ),
                Text(
                  blocked ? intl.credentialsNoAll : intl.credentialsSwitchHint,
                  style: TextStyle(fontSize: 12, color: c.textTertiary),
                ),
              ],
            ),
          ),
          Switch(
            value: _credentials && !blocked,
            activeThumbColor: c.onLilac,
            activeTrackColor: c.lilac,
            onChanged: blocked
                ? null
                : (on) => setState(() {
                    _credentials = on;
                    _clearErrors();
                  }),
          ),
        ],
      ),
    );
  }
}

///an origin as a chip; with [onRemove], a trash button to take it out
class _OriginChip extends StatelessWidget {
  final String origin;
  final bool error;
  final VoidCallback? onRemove;

  const _OriginChip(this.origin, {this.error = false, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      height: 26,
      padding: EdgeInsets.only(left: 8, right: onRemove == null ? 8 : 2),
      decoration: BoxDecoration(
        color: c.night,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: error ? c.danger : c.outlineCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              origin,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 12, color: error ? c.dangerText : c.text),
            ),
          ),
          if (onRemove != null)
            AppIconButton(
              icon: app.assets.icons.actions.delete,
              tooltip: context.intl.cors.removeOrigin(origin: origin),
              hoverColor: c.softRed,
              size: 22,
              iconSize: 12,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

///a warning that doesn't block saving (the api has the last word)
class _Warning extends StatelessWidget {
  final String text;

  const _Warning(this.text);

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.danger.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          app.assets.icons.general.alertTriangle.build(
            size: 14,
            color: c.dangerText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: c.dangerText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
