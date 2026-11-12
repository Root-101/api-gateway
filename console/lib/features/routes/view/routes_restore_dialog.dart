import 'dart:convert';
import 'dart:ui' show PathMetric;

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

///two steps: pick a valid backup, then confirm replacing every current route
class RoutesRestoreDialog extends StatefulWidget {
  static void show() {
    app.dialog.open(
      dialog: BlocProvider(
        create: (BuildContext context) =>
            RoutesRestoreCubit(repo: app.di.find()),
        lazy: false,
        child: const RoutesRestoreDialog(),
      ),
    );
  }

  const RoutesRestoreDialog({super.key});

  @override
  State<RoutesRestoreDialog> createState() => _RoutesRestoreDialogState();
}

class _RoutesRestoreDialogState extends State<RoutesRestoreDialog> {
  late DropzoneViewController _dropzone;
  late final RoutesRestoreCubit cubit;

  String? _filename;
  String? _rawContent;
  List<String>? _routeNames;
  String? _error;
  bool _dragging = false;
  bool _confirming = false;

  List<String> get _currentNames =>
      app.di.find<RoutesCubit>().routes.map((r) => r.name).toList();

  @override
  void initState() {
    super.initState();
    cubit = context.read();
  }

  Future<void> _pick() async {
    final files = await _dropzone.pickFiles();
    if (files.isNotEmpty) _load(files.first);
  }

  Future<void> _load(DropzoneFileInterface file) async {
    setState(() => _dragging = false);
    final name = file.name;
    try {
      final content = utf8.decode(await _dropzone.getFileData(file));
      final names = cubit.repo.parseBackup(content).map((r) => r.name).toList();
      final seen = <String>{};
      //exact match, like the api (names are case-sensitive)
      final repeated = names.where((n) => !seen.add(n)).toSet();
      if (repeated.isNotEmpty) {
        _fail(
          name,
          app.intl.restore.duplicatedNames(names: repeated.join(', ')),
        );
        return;
      }
      setState(() {
        _filename = name;
        _rawContent = content;
        _routeNames = names;
        _error = null;
      });
    } on GlobalException catch (exc) {
      _fail(name, exc.message);
    } catch (_) {
      _fail(name, app.intl.restore.invalidFile);
    }
  }

  void _fail(String name, String message) {
    setState(() {
      _filename = name;
      _rawContent = null;
      _routeNames = null;
      _error = message;
    });
  }

  void _onState(BuildContext context, RoutesRestoreState state) {
    if (state is RoutesRestoreProcessingState) {
      app.loading.show();
    } else if (state is RoutesRestoreOkState) {
      app.loading.hide();
      app.di.find<RoutesCubit>().query.value = '';
      app.snack.showSuccess(
        message: context.intl.restore.restored(count: state.count),
      );
      Navigator.of(context).pop();
    } else if (state is RoutesRestoreErrorState) {
      app.loading.hide();
      app.snack.showError(message: state.exception.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final intl = context.intl;
    return BlocListener<RoutesRestoreCubit, RoutesRestoreState>(
      listener: _onState,
      child: DialogTemplate(
        title: intl.restore.title,
        subtitle: intl.restore.subtitle,
        width: 560,
        alignment: Alignment.center,
        body: _confirming ? _buildConfirm(context) : _buildPicker(context),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: _confirming
              ? [
                  AppButton(
                    label: intl.actions.back,
                    kind: AppButtonKind.outlined,
                    height: 44,
                    autofocus: true,
                    onPressed: () => setState(() => _confirming = false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: intl.restore.replace,
                    icon: app.assets.icons.actions.upload,
                    kind: AppButtonKind.danger,
                    height: 44,
                    onPressed: () =>
                        cubit.restore(rawFileContent: _rawContent!),
                  ),
                ]
              : [
                  AppButton(
                    label: intl.actions.cancel,
                    kind: AppButtonKind.outlined,
                    height: 44,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: intl.routes.restore,
                    icon: app.assets.icons.actions.upload,
                    height: 44,
                    onPressed: _routeNames == null
                        ? null
                        : () => setState(() => _confirming = true),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildPicker(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final ok = _routeNames != null;
    final failed = _error != null;
    final accent = _dragging
        ? c.lilac
        : failed
        ? c.softRed
        : ok
        ? c.success
        : c.outline;
    final hint = failed
        ? _error!
        : ok
        ? intl.restore.ready(count: _routeNames!.length)
        : intl.restore.hint;
    return SizedBox(
      height: 240,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: accent),
        child: Container(
          decoration: BoxDecoration(
            color: _dragging
                ? c.lilac.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DropzoneView(
                  operation: DragOperation.copy,
                  onCreated: (controller) => _dropzone = controller,
                  onHover: () => setState(() => _dragging = true),
                  onLeave: () => setState(() => _dragging = false),
                  onDropFile: _load,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ok
                              ? c.successDot.withValues(alpha: 0.14)
                              : c.raised,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child:
                            (ok
                                    ? app.assets.icons.general.checkCircle
                                    : app.assets.icons.general.fileUp)
                                .build(
                                  size: 26,
                                  color: ok ? c.success : c.lilac,
                                ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _filename ??
                            (_dragging
                                ? intl.restore.releaseFile
                                : intl.restore.dropFileHere),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: failed
                              ? c.softRed
                              : (ok ? c.success : c.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: intl.restore.selectFile,
                        icon: app.assets.icons.general.folderOpen,
                        kind: AppButtonKind.tonal,
                        autofocus: true,
                        onPressed: _pick,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final current = _currentNames;
    final next = _routeNames!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                app.assets.icons.general.alertTriangle.build(
                  size: 20,
                  color: c.dangerText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intl.restore.confirmTitle(
                          current: current.length,
                          next: next.length,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.dangerText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text: '${intl.restore.confirmStart} ',
                          children: [
                            TextSpan(text: _filename, style: monoStyle()),
                            TextSpan(text: intl.restore.confirmEnd),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _namesBox(
                  title: intl.restore.current(count: current.length),
                  titleColor: c.textSecondary,
                  border: c.raised,
                  names: current,
                  style: monoStyle(color: c.textTertiary, height: 20 / 13)
                      .copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: c.textTertiary,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _namesBox(
                  title: intl.restore.fromBackup(count: next.length),
                  titleColor: c.lilac,
                  border: c.lilac.withValues(alpha: 0.35),
                  names: next,
                  style: monoStyle(color: c.text, height: 20 / 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _namesBox({
    required String title,
    required Color titleColor,
    required Color border,
    required List<String> names,
    required TextStyle style,
  }) {
    final c = app.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaptionText(title, color: titleColor, size: 11),
          const SizedBox(height: 6),
          for (final name in names)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    for (final PathMetric metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
