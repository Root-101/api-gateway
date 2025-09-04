import 'dart:convert';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

class RoutesRestoreDialog extends StatefulWidget {
  static void show() {
    DialogTemplate.open(
      title: app.intl.restore,
      w: 650,
      h: 400,
      child: BlocProvider(
        create:
            (BuildContext context) =>
                RoutesRestoreCubit(auth: app.di.find(), repo: app.di.find()),
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
  late DropzoneViewController controller1;
  String? filename;
  String? rawFileContent;
  bool highlighted = false;

  late final RoutesRestoreCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: BlocListener<RoutesRestoreCubit, RoutesRestoreState>(
        listener: (context, state) {
          if (state is RoutesRestoreProcessingState) {
            app.loading.show();
          } else if (state is RoutesRestoreOkState) {
            app.loading.hide();
            app.navigator.pop();
          } else if (state is RoutesRestoreErrorState) {
            app.loading.hide();
            app.snack.showError(
              message: state.exception.message,
              context: context,
            );
          }
        },
        child: Container(
          color: app.colors.primary.backgroundForm,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: app.dimensions.border.borderRadius.l,
                    color:
                        highlighted
                            ? app.colors.primary.background3.brighten(0.1)
                            : app.colors.primary.background3,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DropzoneView(
                          operation: DragOperation.copy,
                          onCreated: (ctrl) => controller1 = ctrl,
                          onHover: () {
                            setState(() => highlighted = true);
                          },
                          onLeave: () {
                            setState(() => highlighted = false);
                          },
                          onDropFile: (file) async {
                            _setupFile(file: file, context: context);
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        top: 0,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SelectionArea(
                                child: Text(
                                  filename == null
                                      ? app.intl.dropFileHere
                                      : filename!,
                                  style: app.textTheme.titleLarge,
                                ),
                              ),
                              app.dimensions.padding.xxl.gap(),
                              PrimaryButton.primary(
                                h: 45,
                                w: 150,
                                color: app.colors.primary.purple,
                                onPressed: () async {
                                  List<DropzoneFileInterface> files =
                                      await controller1.pickFiles();
                                  if (files.isNotEmpty) {
                                    _setupFile(
                                      file: files.first,
                                      context: context,
                                    );
                                  }
                                },
                                icon: app.assets.icons.general.folderOpen,
                                title: app.intl.selectFile,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              app.dimensions.padding.xl.gap(),
              PrimaryButton.primary(
                onPressed: () {
                  if (rawFileContent != null) {
                    cubit.restore(rawFileContent: rawFileContent!);
                  }
                },
                icon: app.assets.icons.actions.upload,
                title: app.intl.restore,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _setupFile({
    required DropzoneFileInterface file,
    required BuildContext context,
  }) async {
    try {
      filename = file.name;
      highlighted = false;

      final bytes = await controller1.getFileData(file);
      rawFileContent = utf8.decode(bytes);

      setState(() {});
    } on Exception {
      filename = null;
      rawFileContent = null;
      app.snack.showError(message: app.intl.errorLoadingFile, context: context);
      setState(() {});
    }
  }
}
