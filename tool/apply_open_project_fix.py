from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f"Esperava 1 ocorrência em {path}, mas encontrei {count}."
        )
    file.write_text(text.replace(old, new), encoding="utf-8")


# Controller: injeta o importador e expõe a abertura como cópia editável.
replace_once(
    "lib/features/cutting_grade/presentation/controllers/grade_controller.dart",
    """import 'package:grade_opera/features/projects/services/project_file_exporter.dart';
""",
    """import 'package:grade_opera/features/projects/services/project_file_exporter.dart';
import 'package:grade_opera/features/projects/services/project_file_importer.dart';
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/controllers/grade_controller.dart",
    """    this.projectFileExporter = const LocalProjectFileExporter(),
    bool startWithStandardGrade = true,
""",
    """    this.projectFileExporter = const LocalProjectFileExporter(),
    this.projectFileImporter = const LocalProjectFileImporter(),
    bool startWithStandardGrade = true,
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/controllers/grade_controller.dart",
    """  final ProjectRepository repository;
  final ProjectFileExporter projectFileExporter;
""",
    """  final ProjectRepository repository;
  final ProjectFileExporter projectFileExporter;
  final ProjectFileImporter projectFileImporter;
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/controllers/grade_controller.dart",
    """    return exportedPath;
  }

  Future<List<ProjectDocument>> listProjects() => repository.listProjects();
""",
    """    return exportedPath;
  }

  Future<ProjectDocument> openProjectFile(String filePath) async {
    try {
      final project = await projectFileImporter.importProject(filePath);
      loadProject(project, asSavedProject: false);
      return project;
    } on ProjectFileImportException catch (error) {
      throw UserVisibleException(error.message);
    }
  }

  Future<List<ProjectDocument>> listProjects() => repository.listProjects();
""",
)

# Tela principal: o botão e Ctrl+O passam a usar o seletor nativo.
replace_once(
    "lib/features/cutting_grade/presentation/pages/grade_main_page.dart",
    """    required this.controller,
    this.selectProjectDirectory,
    super.key,
""",
    """    required this.controller,
    this.selectProjectDirectory,
    this.selectProjectFile,
    super.key,
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/pages/grade_main_page.dart",
    """  final GradeController controller;
  final Future<String?> Function()? selectProjectDirectory;
""",
    """  final GradeController controller;
  final Future<String?> Function()? selectProjectDirectory;
  final Future<String?> Function()? selectProjectFile;
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/pages/grade_main_page.dart",
    """                _compactAction(
                  tooltip: 'Abrir projeto',
                  icon: Icons.folder_open_outlined,
                  onPressed: () => unawaited(_openProjects()),
                ),
""",
    """                _compactAction(
                  tooltip: 'Abrir arquivo · Ctrl+O',
                  key: const Key('abrir-arquivo'),
                  icon: Icons.folder_open_outlined,
                  onPressed: () => unawaited(_openProjects()),
                ),
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/pages/grade_main_page.dart",
    """                OutlinedButton.icon(
                  onPressed: () => unawaited(_openProjects()),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Abrir projeto'),
                ),
""",
    """                OutlinedButton.icon(
                  key: const Key('abrir-arquivo'),
                  onPressed: () => unawaited(_openProjects()),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Abrir arquivo'),
                ),
""",
)

replace_once(
    "lib/features/cutting_grade/presentation/pages/grade_main_page.dart",
    """  Future<void> _openProjects() async {
    await _showProjectPicker(history: false);
  }

  Future<void> _openHistory() async {
""",
    """  Future<void> _openProjects() async {
    if (controller.isDirty) {
      final discard = await _confirm(
        title: 'Abrir outro projeto?',
        message:
            'As alterações não salvas serão descartadas. Deseja continuar?',
        confirmLabel: 'Abrir arquivo',
      );
      if (!discard || !mounted) {
        return;
      }
    }

    final filePath = await _selectProjectFile();
    if (filePath == null || filePath.trim().isEmpty || !mounted) {
      return;
    }

    await _runGuarded(() async {
      final project = await controller.openProjectFile(filePath);
      if (!mounted) {
        return;
      }
      setState(() => _showCompactResults = project.result != null);
      _showMessage(
        'Projeto "${project.orderName}" aberto com sucesso. '
        'Use "Salvar como" para escolher onde salvar as alterações.',
      );
    });
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

  Future<void> _openHistory() async {
""",
)

# O aplicativo volta a usar diretamente a tela principal.
replace_once(
    "lib/app/grade_opera_app.dart",
    """import 'package:grade_opera/features/projects/presentation/pages/grade_project_file_page.dart';
""",
    """import 'package:grade_opera/features/cutting_grade/presentation/pages/grade_main_page.dart';
""",
)

replace_once(
    "lib/app/grade_opera_app.dart",
    """      home: GradeProjectFilePage(controller: _controller),
""",
    """      home: GradeMainPage(controller: _controller),
""",
)

# Remove a solução provisória que sobrepunha um botão transparente.
wrapper = Path(
    "lib/features/projects/presentation/pages/grade_project_file_page.dart"
)
if wrapper.exists():
    wrapper.unlink()

# Documentação.
replace_once(
    "README.md",
    """- seleção da pasta de destino no **Salvar como**, com uma cópia individual
  `.gradeopera.json` e nomes incrementais para não sobrescrever arquivos;
- histórico dos 100 cálculos mais recentes;
""",
    """- seleção da pasta de destino no **Salvar como**, com uma cópia individual
  `.gradeopera.json` e nomes incrementais para não sobrescrever arquivos;
- botão **Abrir arquivo** para navegar até qualquer pasta e importar projetos
  `.gradeopera.json` como cópias editáveis, preservando o arquivo original;
- uso de **Salvar como** para escolher o destino das alterações feitas em um
  projeto importado;
- histórico dos 100 cálculos mais recentes;
""",
)

replace_once(
    "README.md",
    """| `Ctrl+O` | abrir projeto |
""",
    """| `Ctrl+O` | abrir um arquivo `.gradeopera.json` |
""",
)

# Teste do fluxo do controller.
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
        BlockDraftData(
          id: 'bloco-m',
          name: 'M',
          lengthText: '5,20',
        ),
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
