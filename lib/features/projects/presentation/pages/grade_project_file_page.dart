import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grade_opera/features/cutting_grade/presentation/controllers/grade_controller.dart';
import 'package:grade_opera/features/cutting_grade/presentation/pages/grade_main_page.dart';
import 'package:grade_opera/features/projects/services/project_file_importer.dart';

class GradeProjectFilePage extends StatefulWidget {
  const GradeProjectFilePage({
    required this.controller,
    this.selectProjectDirectory,
    this.selectProjectFile,
    super.key,
  });

  final GradeController controller;
  final Future<String?> Function()? selectProjectDirectory;
  final Future<String?> Function()? selectProjectFile;

  @override
  State<GradeProjectFilePage> createState() => _GradeProjectFilePageState();
}

class _GradeProjectFilePageState extends State<GradeProjectFilePage> {
  final GlobalKey _rootKey = GlobalKey();
  final GlobalKey _pageKey = GlobalKey();
  final ProjectFileImporter _projectFileImporter =
      const LocalProjectFileImporter();

  Rect? _openButtonRect;
  Size? _lastLayoutSize;
  bool _locationScheduled = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    widget.controller.addListener(_scheduleOpenButtonLocation);
    _scheduleOpenButtonLocation();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    widget.controller.removeListener(_scheduleOpenButtonLocation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
      if (_lastLayoutSize != layoutSize) {
        _lastLayoutSize = layoutSize;
        _scheduleOpenButtonLocation();
      }

      return SizedBox.expand(
        key: _rootKey,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            KeyedSubtree(
              key: _pageKey,
              child: GradeMainPage(
                controller: widget.controller,
                selectProjectDirectory: widget.selectProjectDirectory,
              ),
            ),
            if (_openButtonRect != null)
              Positioned.fromRect(
                rect: _openButtonRect!,
                child: Semantics(
                  button: true,
                  label: 'Abrir arquivo',
                  child: Tooltip(
                    message: 'Abrir arquivo · Ctrl+O',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: const Key('abrir-arquivo'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => unawaited(_openProjectFile()),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.keyO) {
      return false;
    }

    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final modifierPressed =
        pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight) ||
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
    if (!modifierPressed) {
      return false;
    }

    unawaited(_openProjectFile());
    return true;
  }

  void _scheduleOpenButtonLocation() {
    if (_locationScheduled) {
      return;
    }
    _locationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationScheduled = false;
      _locateOpenButton();
    });
  }

  void _locateOpenButton() {
    if (!mounted) {
      return;
    }

    final pageContext = _pageKey.currentContext;
    final rootRenderObject = _rootKey.currentContext?.findRenderObject();
    if (pageContext is! Element || rootRenderObject is! RenderBox) {
      return;
    }

    final target = _findOpenButton(pageContext);
    final targetRenderObject = target?.findRenderObject();
    if (targetRenderObject is! RenderBox ||
        !targetRenderObject.hasSize ||
        !rootRenderObject.hasSize) {
      if (_openButtonRect != null) {
        setState(() => _openButtonRect = null);
      }
      return;
    }

    final topLeft = targetRenderObject.localToGlobal(
      Offset.zero,
      ancestor: rootRenderObject,
    );
    final nextRect = topLeft & targetRenderObject.size;
    if (_openButtonRect != nextRect) {
      setState(() => _openButtonRect = nextRect);
    }
  }

  Element? _findOpenButton(Element root) {
    Element? result;

    void visit(Element element) {
      if (result != null) {
        return;
      }

      final currentWidget = element.widget;
      if (currentWidget is IconButton &&
          currentWidget.tooltip == 'Abrir projeto') {
        result = element;
        return;
      }
      if (currentWidget is OutlinedButton &&
          _containsText(element, 'Abrir projeto')) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    root.visitChildElements(visit);
    return result;
  }

  bool _containsText(Element root, String expectedText) {
    var found = false;

    void visit(Element element) {
      if (found) {
        return;
      }
      final currentWidget = element.widget;
      if (currentWidget is Text && currentWidget.data == expectedText) {
        found = true;
        return;
      }
      element.visitChildElements(visit);
    }

    root.visitChildElements(visit);
    return found;
  }

  Future<String?> _selectProjectFile() async {
    final customSelector = widget.selectProjectFile;
    if (customSelector != null) {
      return customSelector();
    }

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecione um projeto do GRADE OPERA',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      allowMultiple: false,
      withData: false,
    );
    return result?.files.single.path;
  }

  Future<void> _openProjectFile() async {
    if (widget.controller.isDirty) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Abrir outro projeto?'),
              content: const Text(
                'As alterações não salvas serão descartadas. '
                'Deseja continuar?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Abrir arquivo'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) {
        return;
      }
    }

    final filePath = await _selectProjectFile();
    if (filePath == null || filePath.trim().isEmpty || !mounted) {
      return;
    }

    try {
      final project = await _projectFileImporter.importProject(filePath);
      widget.controller.loadProject(project, asSavedProject: false);
      if (!mounted) {
        return;
      }
      _showMessage(
        'Projeto "${project.orderName}" aberto com sucesso. '
        'Use "Salvar como" para escolher onde salvar as alterações.',
      );
    } on ProjectFileImportException catch (error) {
      _showMessage(error.message, isError: true);
    } on Object {
      _showMessage(
        'Não foi possível abrir o arquivo selecionado.',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
  }
}
