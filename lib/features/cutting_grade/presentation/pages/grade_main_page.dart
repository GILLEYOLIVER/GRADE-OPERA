import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grade_opera/core/constants/app_constants.dart';
import 'package:grade_opera/core/formatting/brazilian_number.dart';
import 'package:grade_opera/features/cutting_grade/presentation/controllers/grade_controller.dart';
import 'package:grade_opera/features/cutting_grade/presentation/widgets/input_sections.dart';
import 'package:grade_opera/features/cutting_grade/presentation/widgets/results_panel.dart';
import 'package:grade_opera/features/reports/services/pdf_report_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:window_manager/window_manager.dart';

class GradeMainPage extends StatefulWidget {
  const GradeMainPage({required this.controller, super.key});

  final GradeController controller;

  @override
  State<GradeMainPage> createState() => _GradeMainPageState();
}

class _GradeMainPageState extends State<GradeMainPage> with WindowListener {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final PdfReportService _pdfService = const PdfReportService();
  bool _allowPop = false;
  bool _showCompactResults = false;

  GradeController get controller => widget.controller;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    if (await _confirmClose() && mounted) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        unawaited(_handlePopRequest());
      }
    },
    child: CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            unawaited(_newProject()),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            unawaited(_saveProject()),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            unawaited(_openProjects()),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () =>
            unawaited(_choosePdfAction()),
        const SingleActivator(LogicalKeyboardKey.f5): () =>
            unawaited(_calculate()),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            unawaited(_deleteSelected()),
      },
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Form(
            key: _formKey,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => LayoutBuilder(
                builder: (context, constraints) {
                  final compactDesktop =
                      _isDesktop &&
                      constraints.maxWidth >= 1200 &&
                      constraints.maxHeight >= 720;
                  return Stack(
                    children: <Widget>[
                      if (compactDesktop)
                        _buildCompactDesktop()
                      else
                        _buildScrollableBody(),
                      if (controller.isCalculating)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.scrim.withValues(alpha: 0.32),
                            child: const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text(
                                        'Calculando a melhor distribuição…',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'O aplicativo continuará responsivo.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildScrollableBody() => SingleChildScrollView(
    controller: _scrollController,
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 700 ? 12 : 24,
      22,
      MediaQuery.sizeOf(context).width < 700 ? 12 : 24,
      40,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 18),
            FabricDataSection(controller: controller),
            const SizedBox(height: 18),
            SizesSection(
              controller: controller,
              onRemove: (id) => unawaited(_removeSize(id)),
            ),
            const SizedBox(height: 18),
            BlocksSection(controller: controller),
            const SizedBox(height: 18),
            CalculationParametersSection(controller: controller),
            const SizedBox(height: 18),
            _buildMainActions(),
            if (controller.result != null) ...<Widget>[
              const SizedBox(height: 18),
              ResultsPanel(result: controller.result!),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _buildCompactDesktop() => Padding(
    key: const Key('painel-compacto'),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildCompactHeader(),
        const SizedBox(height: 8),
        if (!(controller.result != null && _showCompactResults)) ...<Widget>[
          _buildMainActions(compact: true),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: controller.result != null && _showCompactResults
              ? CompactResultsPanel(
                  result: controller.result!,
                  onBack: () => setState(() => _showCompactResults = false),
                  onPdf: () => unawaited(_generatePdf()),
                  onPrint: () => unawaited(_printResult()),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: SizesSection(
                        controller: controller,
                        compact: true,
                        onRemove: (id) => unawaited(_removeSize(id)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          FabricDataSection(
                            controller: controller,
                            compact: true,
                          ),
                          const SizedBox(height: 8),
                          BlocksSection(controller: controller, compact: true),
                          const SizedBox(height: 8),
                          Expanded(
                            child: CalculationParametersSection(
                              controller: controller,
                              compact: true,
                              fillAvailable: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );

  Widget _buildCompactHeader() => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: <Color>[
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.tertiary,
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/logo_opera.jpg',
            width: 108,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppConstants.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton.tonalIcon(
          key: const Key('carregar-exemplo'),
          onPressed: _loadExample,
          icon: const Icon(Icons.science_outlined, size: 18),
          label: const Text('Exemplo'),
        ),
      ],
    ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    title: const Text(
      AppConstants.appName,
      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
    ),
    actions: <Widget>[
      if (controller.isDirty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Tooltip(
            message: 'Existem alterações não salvas',
            child: Icon(Icons.circle, size: 10),
          ),
        ),
      IconButton(
        tooltip: 'Alternar tema claro/escuro',
        onPressed: controller.toggleTheme,
        icon: Icon(
          controller.themeMode == ThemeMode.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        ),
      ),
      IconButton(
        tooltip: 'Histórico de cálculos',
        onPressed: () => unawaited(_openHistory()),
        icon: const Icon(Icons.history),
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: <Color>[
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.tertiary,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth < 700
                  ? constraints.maxWidth
                  : constraints.maxWidth - 260,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo_opera.jpg',
                    width: 180,
                    height: 66,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            key: const Key('carregar-exemplo'),
            onPressed: _loadExample,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Carregar exemplo'),
          ),
        ],
      ),
    ),
  );

  Widget _buildMainActions({bool compact = false}) => Card(
    child: Padding(
      padding: EdgeInsets.all(compact ? 8 : 18),
      child: compact
          ? Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('calcular-distribuicao'),
                    onPressed: controller.isCalculating
                        ? null
                        : () => unawaited(_calculate()),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Calcular · F5'),
                  ),
                ),
                const SizedBox(width: 6),
                _compactAction(
                  tooltip: 'Limpar formulário',
                  key: const Key('limpar-formulario'),
                  icon: Icons.note_add_outlined,
                  onPressed: () => unawaited(_newProject()),
                ),
                _compactAction(
                  tooltip: 'Salvar projeto',
                  icon: Icons.save_outlined,
                  onPressed: () => unawaited(_saveProject()),
                ),
                _compactAction(
                  tooltip: 'Abrir projeto',
                  icon: Icons.folder_open_outlined,
                  onPressed: () => unawaited(_openProjects()),
                ),
                _compactAction(
                  tooltip: 'Histórico',
                  icon: Icons.history,
                  onPressed: () => unawaited(_openHistory()),
                ),
                _compactAction(
                  tooltip: 'Gerar PDF',
                  key: const Key('gerar-pdf'),
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: controller.result == null
                      ? null
                      : () => unawaited(_generatePdf()),
                ),
                _compactAction(
                  tooltip: 'Imprimir resultado',
                  key: const Key('imprimir-resultado'),
                  icon: Icons.print_outlined,
                  onPressed: controller.result == null
                      ? null
                      : () => unawaited(_printResult()),
                ),
              ],
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  key: const Key('calcular-distribuicao'),
                  onPressed: controller.isCalculating
                      ? null
                      : () => unawaited(_calculate()),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calcular distribuição  ·  F5'),
                ),
                OutlinedButton.icon(
                  key: const Key('limpar-formulario'),
                  onPressed: () => unawaited(_newProject()),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Limpar formulário'),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_saveProject()),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar projeto'),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_openProjects()),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Abrir projeto'),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_openHistory()),
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico'),
                ),
                OutlinedButton.icon(
                  key: const Key('gerar-pdf'),
                  onPressed: controller.result == null
                      ? null
                      : () => unawaited(_generatePdf()),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Gerar PDF'),
                ),
                OutlinedButton.icon(
                  key: const Key('imprimir-resultado'),
                  onPressed: controller.result == null
                      ? null
                      : () => unawaited(_printResult()),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Imprimir resultado'),
                ),
              ],
            ),
    ),
  );

  Widget _compactAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Key? key,
  }) => IconButton(
    key: key,
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    visualDensity: VisualDensity.compact,
  );

  Future<void> _calculate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage(
        'Revise os campos destacados antes de calcular.',
        isError: true,
      );
      return;
    }
    await _runGuarded(() async {
      final result = await controller.calculate();
      if (mounted) {
        setState(() => _showCompactResults = true);
      }
      _showMessage(
        'Distribuição calculada: '
        '${BrazilianNumber.metersFromMicrometers(result.usedMicrometers)} m '
        'utilizados e '
        '${BrazilianNumber.metersFromMicrometers(result.remainingMicrometers)} m '
        'de sobra.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _loadExample() {
    controller.loadExample();
    setState(() => _showCompactResults = false);
    _showMessage(
      'Exemplo de 115 metros carregado. Pressione F5 para calcular.',
    );
  }

  Future<void> _newProject() async {
    if (controller.isDirty) {
      final discard = await _confirm(
        title: 'Limpar formulário?',
        message:
            'As alterações não salvas serão descartadas. Deseja continuar?',
        confirmLabel: 'Limpar',
      );
      if (!discard) {
        return;
      }
    }
    controller.clearForm();
    setState(() => _showCompactResults = false);
  }

  Future<void> _saveProject() async {
    await _runGuarded(() async {
      await controller.saveProject();
      _showMessage('Projeto salvo com segurança na pasta de dados do usuário.');
    });
  }

  Future<void> _removeSize(String id) async {
    final size = controller.sizes.firstWhere((item) => item.id == id);
    final confirmed = await _confirm(
      title: 'Remover tamanho?',
      message:
          'O tamanho "${size.nameController.text}" será removido. Esta ação exige novo cálculo.',
      confirmLabel: 'Remover',
    );
    if (confirmed) {
      controller.removeSize(id);
    }
  }

  Future<void> _deleteSelected() async {
    if (controller.selectedSizeId != null) {
      await _removeSize(controller.selectedSizeId!);
    } else if (controller.selectedBlockId != null) {
      _showMessage(
        'Os blocos são automáticos. Remova um tamanho ou altere sua porcentagem.',
      );
    } else {
      _showMessage(
        'Selecione uma linha de tamanho ou bloco antes de pressionar Delete.',
      );
    }
  }

  Future<void> _openProjects() async {
    await _showProjectPicker(history: false);
  }

  Future<void> _openHistory() async {
    await _showProjectPicker(history: true);
  }

  Future<void> _showProjectPicker({required bool history}) async {
    await _runGuarded(() async {
      var items = history
          ? await controller.listHistory()
          : await controller.listProjects();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(history ? 'Histórico de cálculos' : 'Projetos salvos'),
            content: SizedBox(
              width: 700,
              height: 420,
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        history
                            ? 'Nenhum cálculo no histórico.'
                            : 'Nenhum projeto salvo.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: Icon(
                            item.result == null
                                ? Icons.description_outlined
                                : Icons.analytics_outlined,
                          ),
                          title: Text(item.orderName),
                          subtitle: Text(
                            '${item.modelCode.isEmpty ? 'Sem código' : item.modelCode}'
                            '  •  ${_formatDate(item.updatedAt)}'
                            '${item.result == null ? '' : '  •  ${BrazilianNumber.metersFromMicrometers(item.result!.usedMicrometers)} m usados'}',
                          ),
                          onTap: () {
                            controller.loadProject(
                              item,
                              asSavedProject: !history,
                            );
                            Navigator.pop(dialogContext);
                          },
                          trailing: history
                              ? const Icon(Icons.chevron_right)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      tooltip: 'Duplicar projeto',
                                      onPressed: () async {
                                        await controller.duplicateProject(
                                          item.id,
                                        );
                                        items = await controller.listProjects();
                                        setDialogState(() {});
                                      },
                                      icon: const Icon(Icons.copy_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Excluir projeto',
                                      onPressed: () async {
                                        final delete = await _confirm(
                                          title: 'Excluir projeto?',
                                          message:
                                              'O projeto "${item.orderName}" será excluído permanentemente.',
                                          confirmLabel: 'Excluir',
                                        );
                                        if (delete) {
                                          await controller.deleteProject(
                                            item.id,
                                          );
                                          items = await controller
                                              .listProjects();
                                          setDialogState(() {});
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _generatePdf() async {
    if (controller.result == null) {
      return;
    }
    await _runGuarded(() async {
      final path = await _pdfService.chooseAndSave(
        controller.toDocument(id: controller.projectId ?? 'relatorio'),
      );
      if (path == null || !mounted) {
        return;
      }
      final open = await _confirm(
        title: 'PDF gerado',
        message: 'O relatório foi salvo em:\n$path\n\nDeseja abri-lo agora?',
        confirmLabel: 'Abrir PDF',
        cancelLabel: 'Agora não',
      );
      if (open) {
        await _pdfService.openFile(path);
      }
    });
  }

  Future<void> _printResult() async {
    if (controller.result == null) {
      return;
    }
    await _runGuarded(() async {
      final project = controller.toDocument(
        id: controller.projectId ?? 'impressao',
      );
      final bytes = await _pdfService.generate(project);
      if (!mounted) {
        return;
      }
      final shouldPrint =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 22,
              ),
              child: SizedBox(
                width: 1120,
                height: MediaQuery.sizeOf(dialogContext).height * 0.9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.preview_outlined,
                            color: Theme.of(dialogContext).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Pré-visualização da impressão',
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Fechar pré-visualização',
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: PdfPreview(
                        key: const Key('pre-visualizacao-impressao'),
                        build: (format) async => bytes,
                        initialPageFormat: PdfPageFormat.a4,
                        allowPrinting: false,
                        allowSharing: false,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        useActions: false,
                        maxPageWidth: 760,
                        pdfFileName: 'GRADE_OPERA_${project.orderName}.pdf',
                        loadingWidget: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Fechar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            key: const Key('confirmar-impressao'),
                            onPressed: () => Navigator.pop(dialogContext, true),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Imprimir'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ) ??
          false;
      if (shouldPrint) {
        await _pdfService.printReport(project, generatedBytes: bytes);
      }
    });
  }

  Future<void> _choosePdfAction() async {
    if (controller.result == null) {
      _showMessage(
        'Calcule uma distribuição válida antes de gerar ou imprimir o PDF.',
        isError: true,
      );
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Relatório em PDF'),
        content: const Text('Escolha o que deseja fazer com o resultado.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'print'),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Imprimir'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Salvar PDF'),
          ),
        ],
      ),
    );
    if (action == 'print') {
      await _printResult();
    } else if (action == 'save') {
      await _generatePdf();
    }
  }

  Future<bool> _confirmClose() async {
    if (!controller.isDirty) {
      return true;
    }
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Existem alterações não salvas'),
        content: const Text('Deseja salvar antes de sair?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Sair sem salvar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Salvar e sair'),
          ),
        ],
      ),
    );
    if (action == 'discard') {
      return true;
    }
    if (action == 'save') {
      try {
        await controller.saveProject();
        return true;
      } on UserVisibleException catch (error) {
        _showMessage(error.message, isError: true);
      } on Object catch (error) {
        _showMessage('Não foi possível salvar: $error', isError: true);
      }
    }
    return false;
  }

  Future<void> _handlePopRequest() async {
    if (await _confirmClose() && mounted) {
      setState(() => _allowPop = true);
      await Navigator.of(context).maybePop();
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _runGuarded(Future<void> Function() operation) async {
    try {
      await operation();
    } on UserVisibleException catch (error) {
      if (mounted) {
        _showMessage(error.message, isError: true);
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Ocorreu um erro inesperado: $error', isError: true);
      }
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

  String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
