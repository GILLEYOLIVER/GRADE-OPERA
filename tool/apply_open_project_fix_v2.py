from pathlib import Path


def ensure_replacement(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    if new in text:
        return
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f"Não foi possível atualizar {path}: esperava 1 ocorrência e encontrei {count}."
        )
    file.write_text(text.replace(old, new), encoding="utf-8")


controller = "lib/features/cutting_grade/presentation/controllers/grade_controller.dart"
page = "lib/features/cutting_grade/presentation/pages/grade_main_page.dart"
app = "lib/app/grade_opera_app.dart"

ensure_replacement(
    controller,
    "import 'package:grade_opera/features/projects/services/project_file_exporter.dart';\n",
    "import 'package:grade_opera/features/projects/services/project_file_exporter.dart';\n"
    "import 'package:grade_opera/features/projects/services/project_file_importer.dart';\n",
)
ensure_replacement(
    controller,
    "    this.projectFileExporter = const LocalProjectFileExporter(),\n"
    "    bool startWithStandardGrade = true,\n",
    "    this.projectFileExporter = const LocalProjectFileExporter(),\n"
    "    this.projectFileImporter = const LocalProjectFileImporter(),\n"
    "    bool startWithStandardGrade = true,\n",
)
ensure_replacement(
    controller,
    "  final ProjectRepository repository;\n"
    "  final ProjectFileExporter projectFileExporter;\n",
    "  final ProjectRepository repository;\n"
    "  final ProjectFileExporter projectFileExporter;\n"
    "  final ProjectFileImporter projectFileImporter;\n",
)
ensure_replacement(
    controller,
    "    return exportedPath;\n"
    "  }\n\n"
    "  Future<List<ProjectDocument>> listProjects() => repository.listProjects();\n",
    "    return exportedPath;\n"
    "  }\n\n"
    "  Future<ProjectDocument> openProjectFile(String filePath) async {\n"
    "    try {\n"
    "      final project = await projectFileImporter.importProject(filePath);\n"
    "      loadProject(project, asSavedProject: false);\n"
    "      return project;\n"
    "    } on ProjectFileImportException catch (error) {\n"
    "      throw UserVisibleException(error.message);\n"
    "    }\n"
    "  }\n\n"
    "  Future<List<ProjectDocument>> listProjects() => repository.listProjects();\n",
)

ensure_replacement(
    page,
    "    required this.controller,\n"
    "    this.selectProjectDirectory,\n"
    "    super.key,\n",
    "    required this.controller,\n"
    "    this.selectProjectDirectory,\n"
    "    this.selectProjectFile,\n"
    "    super.key,\n",
)
ensure_replacement(
    page,
    "  final GradeController controller;\n"
    "  final Future<String?> Function()? selectProjectDirectory;\n",
    "  final GradeController controller;\n"
    "  final Future<String?> Function()? selectProjectDirectory;\n"
    "  final Future<String?> Function()? selectProjectFile;\n",
)
ensure_replacement(
    page,
    "                _compactAction(\n"
    "                  tooltip: 'Abrir projeto',\n"
    "                  icon: Icons.folder_open_outlined,\n"
    "                  onPressed: () => unawaited(_openProjects()),\n"
    "                ),\n",
    "                _compactAction(\n"
    "                  tooltip: 'Abrir arquivo · Ctrl+O',\n"
    "                  key: const Key('abrir-arquivo'),\n"
    "                  icon: Icons.folder_open_outlined,\n"
    "                  onPressed: () => unawaited(_openProjects()),\n"
    "                ),\n",
)
ensure_replacement(
    page,
    "                OutlinedButton.icon(\n"
    "                  onPressed: () => unawaited(_openProjects()),\n"
    "                  icon: const Icon(Icons.folder_open_outlined),\n"
    "                  label: const Text('Abrir projeto'),\n"
    "                ),\n",
    "                OutlinedButton.icon(\n"
    "                  key: const Key('abrir-arquivo'),\n"
    "                  onPressed: () => unawaited(_openProjects()),\n"
    "                  icon: const Icon(Icons.folder_open_outlined),\n"
    "                  label: const Text('Abrir arquivo'),\n"
    "                ),\n",
)
ensure_replacement(
    page,
    "  Future<void> _openProjects() async {\n"
    "    await _showProjectPicker(history: false);\n"
    "  }\n\n"
    "  Future<void> _openHistory() async {\n",
    "  Future<void> _openProjects() async {\n"
    "    if (controller.isDirty) {\n"
    "      final discard = await _confirm(\n"
    "        title: 'Abrir outro projeto?',\n"
    "        message:\n"
    "            'As alterações não salvas serão descartadas. Deseja continuar?',\n"
    "        confirmLabel: 'Abrir arquivo',\n"
    "      );\n"
    "      if (!discard || !mounted) {\n"
    "        return;\n"
    "      }\n"
    "    }\n\n"
    "    final filePath = await _selectProjectFile();\n"
    "    if (filePath == null || filePath.trim().isEmpty || !mounted) {\n"
    "      return;\n"
    "    }\n\n"
    "    await _runGuarded(() async {\n"
    "      final project = await controller.openProjectFile(filePath);\n"
    "      if (!mounted) {\n"
    "        return;\n"
    "      }\n"
    "      setState(() => _showCompactResults = project.result != null);\n"
    "      _showMessage(\n"
    "        'Projeto \"${project.orderName}\" aberto com sucesso. '\n"
    "        'Use \"Salvar como\" para escolher onde salvar as alterações.',\n"
    "      );\n"
    "    });\n"
    "  }\n\n"
    "  Future<String?> _selectProjectFile() async {\n"
    "    final customSelector = widget.selectProjectFile;\n"
    "    if (customSelector != null) {\n"
    "      return customSelector();\n"
    "    }\n\n"
    "    final result = await FilePicker.platform.pickFiles(\n"
    "      dialogTitle: 'Selecione um projeto do GRADE OPERA',\n"
    "      type: FileType.custom,\n"
    "      allowedExtensions: const <String>['json'],\n"
    "      allowMultiple: false,\n"
    "      withData: false,\n"
    "    );\n"
    "    return result?.files.single.path;\n"
    "  }\n\n"
    "  Future<void> _openHistory() async {\n",
)

ensure_replacement(
    app,
    "import 'package:grade_opera/features/projects/presentation/pages/grade_project_file_page.dart';\n",
    "import 'package:grade_opera/features/cutting_grade/presentation/pages/grade_main_page.dart';\n",
)
ensure_replacement(
    app,
    "      home: GradeProjectFilePage(controller: _controller),\n",
    "      home: GradeMainPage(controller: _controller),\n",
)

wrapper = Path("lib/features/projects/presentation/pages/grade_project_file_page.dart")
if wrapper.exists():
    wrapper.unlink()

ensure_replacement(
    "README.md",
    "- seleção da pasta de destino no **Salvar como**, com uma cópia individual\n"
    "  `.gradeopera.json` e nomes incrementais para não sobrescrever arquivos;\n"
    "- histórico dos 100 cálculos mais recentes;\n",
    "- seleção da pasta de destino no **Salvar como**, com uma cópia individual\n"
    "  `.gradeopera.json` e nomes incrementais para não sobrescrever arquivos;\n"
    "- botão **Abrir arquivo** para navegar até qualquer pasta e importar projetos\n"
    "  `.gradeopera.json` como cópias editáveis, preservando o arquivo original;\n"
    "- uso de **Salvar como** para escolher o destino das alterações feitas em um\n"
    "  projeto importado;\n"
    "- histórico dos 100 cálculos mais recentes;\n",
)
ensure_replacement(
    "README.md",
    "| `Ctrl+O` | abrir projeto |\n",
    "| `Ctrl+O` | abrir um arquivo `.gradeopera.json` |\n",
)

Path("test/features/projects/project_file_open_controller_test.dart").write_text(
    """import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/cutting_grade/presentation/controllers/grade_controller.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/projects/services/project_file_importer.dart';

import '../../support/in_memory_project_repository.dart';

void main() {
  test('abre projeto externo como cópia editável', () async {
    final project = ProjectDocument(
      id: 'arquivo-1',
      orderName: 'MODELO-IMPORTADO',
      modelCode: 'MODELO-IMPORTADO',
      modelDescription: 'Descrição importada',
      desiredQuantityText: '250',
      fabricText: '75',
      overlapText: '4,5',
      notes: 'Observação importada',
      sizes: const <SizeDraftData>[
        SizeDraftData(
          id: 'tamanho-m',
          name: 'M',
          percentageText: '100',
          blockId: 'bloco-m',
        ),
      ],
      blocks: const <BlockDraftData>[
        BlockDraftData(id: 'bloco-m', name: 'M', lengthText: '5,20'),
      ],
      fabricColors: const <FabricColorDraftData>[
        FabricColorDraftData(
          id: 'cor-preta',
          colorName: 'Preto',
          metersText: '75',
        ),
      ],
      result: null,
      createdAt: DateTime(2026, 7, 24),
      updatedAt: DateTime(2026, 7, 24),
    );
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      projectFileImporter: _StubProjectFileImporter(project),
      startWithStandardGrade: false,
    );
    addTearDown(controller.dispose);

    final opened = await controller.openProjectFile(
      r'C:\Projetos\MODELO-IMPORTADO.gradeopera.json',
    );

    expect(opened, same(project));
    expect(controller.projectId, isNull);
    expect(controller.isDirty, isTrue);
    expect(controller.modelCodeController.text, 'MODELO-IMPORTADO');
    expect(controller.descriptionController.text, 'Descrição importada');
    expect(controller.desiredQuantityController.text, '250');
    expect(controller.overlapController.text, '4,5');
    expect(controller.notesController.text, 'Observação importada');
    expect(controller.sizes.single.nameController.text, 'M');
    expect(controller.blocks.single.lengthText, '5,20');
    expect(controller.fabricColors.single.colorNameController.text, 'Preto');
    expect(controller.fabricColors.single.metersController.text, '75');
  });

  test('converte erro de importação em mensagem visível', () async {
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      projectFileImporter: const _FailingProjectFileImporter(),
    );
    addTearDown(controller.dispose);

    await expectLater(
      controller.openProjectFile('invalido.gradeopera.json'),
      throwsA(
        isA<UserVisibleException>().having(
          (error) => error.message,
          'message',
          'Arquivo de teste inválido.',
        ),
      ),
    );
  });
}

class _StubProjectFileImporter implements ProjectFileImporter {
  const _StubProjectFileImporter(this.project);

  final ProjectDocument project;

  @override
  Future<ProjectDocument> importProject(String filePath) async => project;
}

class _FailingProjectFileImporter implements ProjectFileImporter {
  const _FailingProjectFileImporter();

  @override
  Future<ProjectDocument> importProject(String filePath) {
    throw const ProjectFileImportException('Arquivo de teste inválido.');
  }
}
""",
    encoding="utf-8",
)
