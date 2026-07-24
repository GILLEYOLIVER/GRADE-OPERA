import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grade_opera/core/formatting/brazilian_number.dart';
import 'package:grade_opera/core/utils/id_generator.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/cutting_grade/domain/services/grade_calculator.dart';
import 'package:grade_opera/features/cutting_grade/domain/services/grade_validator.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/projects/domain/repositories/project_repository.dart';

class UserVisibleException implements Exception {
  const UserVisibleException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EditableSize {
  EditableSize({
    required this.id,
    required String name,
    required String percentage,
    required this.blockId,
    required VoidCallback onChanged,
  }) : nameController = TextEditingController(text: name),
       percentageController = TextEditingController(text: percentage) {
    nameController.addListener(onChanged);
    percentageController.addListener(onChanged);
  }

  final String id;
  final TextEditingController nameController;
  final TextEditingController percentageController;
  String? blockId;

  void dispose() {
    nameController.dispose();
    percentageController.dispose();
  }
}

class EditableBlock {
  const EditableBlock({
    required this.id,
    required this.name,
    required this.lengthText,
  });

  final String id;
  final String name;
  final String lengthText;

  EditableBlock copyWith({String? name, String? lengthText}) => EditableBlock(
    id: id,
    name: name ?? this.name,
    lengthText: lengthText ?? this.lengthText,
  );
}

class EditableFabricColor {
  EditableFabricColor({
    required this.id,
    required String colorName,
    required String metersText,
    required VoidCallback onChanged,
  }) : colorNameController = TextEditingController(text: colorName),
       metersController = TextEditingController(text: metersText) {
    colorNameController.addListener(onChanged);
    metersController.addListener(onChanged);
  }

  final String id;
  final TextEditingController colorNameController;
  final TextEditingController metersController;

  void dispose() {
    colorNameController.dispose();
    metersController.dispose();
  }
}

class GradeController extends ChangeNotifier {
  GradeController({
    required this.repository,
    bool startWithStandardGrade = true,
  }) {
    for (final controller in _mainControllers) {
      controller.addListener(_markDirty);
    }
    _withoutDirty(() {
      addFabricColor();
      if (startWithStandardGrade) {
        addStandardSizes();
      }
    });
    if (startWithStandardGrade) {
      selectedSizeId = null;
    }
    isDirty = false;
  }

  final ProjectRepository repository;
  final TextEditingController modelCodeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController desiredQuantityController =
      TextEditingController();
  final TextEditingController overlapController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  late final List<TextEditingController> _mainControllers =
      <TextEditingController>[
        modelCodeController,
        descriptionController,
        desiredQuantityController,
        overlapController,
        notesController,
      ];

  final List<EditableSize> sizes = <EditableSize>[];
  final List<EditableBlock> blocks = <EditableBlock>[];
  final List<EditableFabricColor> fabricColors = <EditableFabricColor>[];
  CalculationResult? result;
  ThemeMode themeMode = ThemeMode.light;
  bool isCalculating = false;
  bool isDirty = false;
  bool _suppressDirty = false;
  Timer? _automaticGroupingTimer;
  String? _projectId;
  DateTime? _createdAt;
  String? selectedSizeId;
  String? selectedBlockId;

  String? get projectId => _projectId;
  TextEditingController get fabricController =>
      fabricColors.first.metersController;

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void addSize({String name = '', String percentage = '100', String? blockId}) {
    sizes.add(
      _createEditableSize(
        id: IdGenerator.create('tamanho'),
        name: name,
        percentage: percentage,
        blockId: blockId,
      ),
    );
    selectedSizeId = sizes.last.id;
    _synchronizeBlocksByPercentage();
    _markDirty();
  }

  void addFabricColor({String? name, String metersText = ''}) {
    fabricColors.add(
      EditableFabricColor(
        id: IdGenerator.create('cor'),
        colorName: name ?? _nextFabricColorName(),
        metersText: metersText,
        onChanged: _markDirty,
      ),
    );
    _markDirty();
  }

  String _nextFabricColorName() {
    final existing = fabricColors
        .map((fabric) => fabric.colorNameController.text.trim().toUpperCase())
        .toSet();
    var number = 1;
    while (existing.contains('COR $number')) {
      number++;
    }
    return 'Cor $number';
  }

  void removeFabricColor(String id) {
    if (fabricColors.length <= 1) {
      return;
    }
    final index = fabricColors.indexWhere((fabric) => fabric.id == id);
    if (index < 0) {
      return;
    }
    fabricColors.removeAt(index).dispose();
    _markDirty();
  }

  void addStandardSizes() {
    const standards = <String>['PP', 'P', 'M', 'G', 'GG', 'G1', 'G2'];
    final existing = sizes
        .map((size) => size.nameController.text.trim().toUpperCase())
        .toSet();
    for (final name in standards) {
      if (!existing.contains(name)) {
        addSize(name: name);
      }
    }
    notifyListeners();
  }

  void removeSize(String id) {
    final index = sizes.indexWhere((size) => size.id == id);
    if (index < 0) {
      return;
    }
    sizes.removeAt(index).dispose();
    if (selectedSizeId == id) {
      selectedSizeId = null;
    }
    result = null;
    _synchronizeBlocksByPercentage();
    _markDirty();
  }

  void setSizeBlock(String sizeId, String? blockId) {
    final size = sizes.firstWhere((item) => item.id == sizeId);
    size.blockId = blockId;
    selectedSizeId = sizeId;
    result = null;
    _markDirty();
  }

  void selectSize(String? id) {
    selectedSizeId = id;
    notifyListeners();
  }

  void selectBlock(String? id) {
    selectedBlockId = id;
    notifyListeners();
  }

  void saveBlock({
    String? id,
    required String name,
    required String lengthText,
    required Set<String> selectedSizeIds,
  }) {
    final blockId = id ?? IdGenerator.create('bloco');
    final index = blocks.indexWhere((block) => block.id == blockId);
    final block = EditableBlock(
      id: blockId,
      name: name.trim(),
      lengthText: lengthText.trim(),
    );
    if (index < 0) {
      blocks.add(block);
    } else {
      blocks[index] = block;
    }
    for (final size in sizes) {
      if (selectedSizeIds.contains(size.id)) {
        size.blockId = blockId;
      } else if (size.blockId == blockId) {
        size.blockId = null;
      }
    }
    selectedBlockId = blockId;
    result = null;
    _markDirty();
  }

  void updateBlockLength(String id, String lengthText) {
    final index = blocks.indexWhere((block) => block.id == id);
    if (index < 0) {
      return;
    }
    blocks[index] = blocks[index].copyWith(lengthText: lengthText.trim());
    selectedBlockId = id;
    result = null;
    _markDirty();
  }

  void removeBlock(String id) {
    blocks.removeWhere((block) => block.id == id);
    for (final size in sizes.where((size) => size.blockId == id)) {
      size.blockId = null;
    }
    if (selectedBlockId == id) {
      selectedBlockId = null;
    }
    result = null;
    _markDirty();
  }

  void duplicateBlock() {
    if (blocks.isEmpty) {
      throw const UserVisibleException(
        'Adicione um bloco antes de usar a duplicação.',
      );
    }
    final source = blocks.firstWhere(
      (block) => block.id == selectedBlockId,
      orElse: () => blocks.last,
    );
    final newId = IdGenerator.create('bloco');
    final newName = _uniqueBlockName('${source.name} — cópia');
    blocks.add(
      EditableBlock(id: newId, name: newName, lengthText: source.lengthText),
    );
    final sourceSizes = sizes
        .where((size) => size.blockId == source.id)
        .toList();
    for (final sourceSize in sourceSizes) {
      addSize(
        name: _uniqueSizeName('${sourceSize.nameController.text} cópia'),
        percentage: sourceSize.percentageController.text,
        blockId: newId,
      );
    }
    selectedBlockId = newId;
    _markDirty();
  }

  Future<CalculationResult> calculate() async {
    if (isCalculating) {
      throw const UserVisibleException('O cálculo já está em andamento.');
    }
    final input = buildCalculationInput();
    final issues = const GradeValidator().validate(input);
    if (issues.isNotEmpty) {
      throw UserVisibleException(
        issues.map((issue) => '• ${issue.message}').join('\n'),
      );
    }
    isCalculating = true;
    notifyListeners();
    try {
      final calculated = await calculateGradeAsync(input);
      if (calculated == null) {
        throw const UserVisibleException(
          'Não foi possível encontrar uma distribuição válida com os dados '
          'informados. Verifique os comprimentos, a margem e a quantidade de '
          'tecido disponível.',
        );
      }
      result = calculated;
      isDirty = true;
      await repository.addHistory(
        toDocument(
          id: IdGenerator.create('historico'),
          resultOverride: calculated,
        ),
      );
      return calculated;
    } finally {
      isCalculating = false;
      notifyListeners();
    }
  }

  CalculationInput buildCalculationInput() {
    final parsedFabricColors = <FabricColorInput>[];
    for (final fabric in fabricColors) {
      final meters = BrazilianNumber.tryParseMetersToMicrometers(
        fabric.metersController.text,
      );
      final colorName = fabric.colorNameController.text.trim();
      if (meters == null) {
        throw UserVisibleException(
          'Informe uma metragem válida para a cor '
          '"${colorName.isEmpty ? 'sem nome' : colorName}", por exemplo 35,50.',
        );
      }
      parsedFabricColors.add(
        FabricColorInput(
          id: fabric.id,
          colorName: colorName,
          availableMicrometers: meters,
        ),
      );
    }
    final totalFabric = parsedFabricColors.fold(
      0,
      (sum, fabric) => sum + fabric.availableMicrometers,
    );
    final overlap = BrazilianNumber.tryParseCentimetersToMicrometers(
      overlapController.text,
    );
    if (overlap == null) {
      throw const UserVisibleException(
        'Informe a margem em centímetros com um número válido, por exemplo 4,5.',
      );
    }
    final parsedSizes = <GradeSize>[];
    for (final size in sizes) {
      final percentage = BrazilianNumber.tryParse(
        size.percentageController.text,
      );
      if (percentage == null) {
        throw UserVisibleException(
          'A porcentagem do tamanho "${size.nameController.text}" é inválida.',
        );
      }
      parsedSizes.add(
        GradeSize(
          id: size.id,
          name: size.nameController.text.trim(),
          desiredPercentage: percentage,
          blockId: size.blockId,
        ),
      );
    }
    final parsedBlocks = <CuttingBlock>[];
    for (final block in blocks) {
      final length = BrazilianNumber.tryParseMetersToMicrometers(
        block.lengthText,
      );
      if (length == null) {
        throw UserVisibleException(
          'O comprimento do bloco "${block.name}" é inválido.',
        );
      }
      parsedBlocks.add(
        CuttingBlock(
          id: block.id,
          name: block.name.trim(),
          lengthMicrometers: length,
        ),
      );
    }
    return CalculationInput(
      availableMicrometers: totalFabric,
      overlapMicrometers: overlap,
      sizes: parsedSizes,
      blocks: parsedBlocks,
      fabricColors: parsedFabricColors,
    );
  }

  Future<void> saveProject() async {
    if (modelCodeController.text.trim().isEmpty &&
        descriptionController.text.trim().isEmpty) {
      throw const UserVisibleException(
        'Informe o código ou a descrição do modelo antes de salvar.',
      );
    }
    final now = DateTime.now();
    _projectId ??= IdGenerator.create('projeto');
    _createdAt ??= now;
    await repository.saveProject(
      toDocument(id: _projectId!, createdAt: _createdAt, updatedAt: now),
    );
    isDirty = false;
    notifyListeners();
  }

  Future<void> saveProjectAs({
    required String modelCode,
    required String modelDescription,
  }) async {
    final newModelCode = modelCode.trim();
    final newModelDescription = modelDescription.trim();
    if (newModelCode.isEmpty && newModelDescription.isEmpty) {
      throw const UserVisibleException(
        'Informe o código ou a descrição do novo modelo.',
      );
    }

    final now = DateTime.now();
    final newProjectId = IdGenerator.create('projeto');
    await repository.saveProject(
      toDocument(
        id: newProjectId,
        createdAt: now,
        updatedAt: now,
        modelCodeOverride: newModelCode,
        modelDescriptionOverride: newModelDescription,
      ),
    );

    _withoutDirty(() {
      modelCodeController.text = newModelCode;
      descriptionController.text = newModelDescription;
      _projectId = newProjectId;
      _createdAt = now;
      isDirty = false;
    });
    notifyListeners();
  }

  Future<List<ProjectDocument>> listProjects() => repository.listProjects();

  Future<List<ProjectDocument>> listHistory() => repository.listHistory();

  Future<void> deleteProject(String id) async {
    await repository.deleteProject(id);
    if (_projectId == id) {
      clearForm();
    }
  }

  Future<ProjectDocument> duplicateProject(String id) =>
      repository.duplicateProject(id);

  void loadProject(ProjectDocument project, {bool asSavedProject = true}) {
    _withoutDirty(() {
      _clearCollections();
      modelCodeController.text = project.modelCode;
      descriptionController.text = project.modelDescription;
      desiredQuantityController.text = project.desiredQuantityText;
      overlapController.text = project.overlapText;
      notesController.text = project.notes;
      if (project.fabricColors.isEmpty) {
        addFabricColor(name: 'Cor 1', metersText: project.fabricText);
      } else {
        for (final fabric in project.fabricColors) {
          fabricColors.add(
            EditableFabricColor(
              id: fabric.id,
              colorName: fabric.colorName,
              metersText: fabric.metersText,
              onChanged: _markDirty,
            ),
          );
        }
      }
      for (final size in project.sizes) {
        sizes.add(
          _createEditableSize(
            id: size.id,
            name: size.name,
            percentage: size.percentageText,
            blockId: size.blockId,
          ),
        );
      }
      blocks.addAll(
        project.blocks.map(
          (block) => EditableBlock(
            id: block.id,
            name: block.name,
            lengthText: block.lengthText,
          ),
        ),
      );
      _synchronizeBlocksByPercentage();
      result = project.result;
      _projectId = asSavedProject ? project.id : null;
      _createdAt = asSavedProject ? project.createdAt : null;
      selectedBlockId = null;
      selectedSizeId = null;
      isDirty = !asSavedProject;
    });
    notifyListeners();
  }

  void loadExample() {
    _withoutDirty(() {
      _clearCollections();
      modelCodeController.text = 'EXEMPLO-115';
      descriptionController.text = 'Distribuição demonstrativa de 115 metros';
      desiredQuantityController.text = '100';
      addFabricColor(name: 'Preto', metersText: '115,00');
      overlapController.text = '4,00';
      notesController.text = 'Exemplo oficial do GRADE OPERA.';
      final mg = IdGenerator.create('bloco');
      final pgg = IdGenerator.create('bloco');
      final pp = IdGenerator.create('bloco');
      blocks.addAll(<EditableBlock>[
        EditableBlock(id: mg, name: 'M/G', lengthText: '5,20'),
        EditableBlock(id: pgg, name: 'P/GG', lengthText: '5,17'),
        EditableBlock(id: pp, name: 'PP', lengthText: '2,40'),
      ]);
      sizes.addAll(<EditableSize>[
        _createEditableSize(
          id: IdGenerator.create('tamanho'),
          name: 'PP',
          percentage: '15',
          blockId: pp,
        ),
        _createEditableSize(
          id: IdGenerator.create('tamanho'),
          name: 'P',
          percentage: '50',
          blockId: pgg,
        ),
        _createEditableSize(
          id: IdGenerator.create('tamanho'),
          name: 'M',
          percentage: '100',
          blockId: mg,
        ),
        _createEditableSize(
          id: IdGenerator.create('tamanho'),
          name: 'G',
          percentage: '100',
          blockId: mg,
        ),
        _createEditableSize(
          id: IdGenerator.create('tamanho'),
          name: 'GG',
          percentage: '50',
          blockId: pgg,
        ),
      ]);
      result = null;
      _projectId = null;
      _createdAt = null;
      isDirty = true;
    });
    notifyListeners();
  }

  void clearForm() {
    _withoutDirty(() {
      _clearCollections();
      for (final controller in _mainControllers) {
        controller.clear();
      }
      addFabricColor();
      result = null;
      _projectId = null;
      _createdAt = null;
      selectedBlockId = null;
      selectedSizeId = null;
      isDirty = false;
    });
    notifyListeners();
  }

  ProjectDocument toDocument({
    required String id,
    DateTime? createdAt,
    DateTime? updatedAt,
    CalculationResult? resultOverride,
    String? modelCodeOverride,
    String? modelDescriptionOverride,
  }) {
    final now = DateTime.now();
    final totalFabric = fabricColors.fold<int>(0, (sum, fabric) {
      final value = BrazilianNumber.tryParseMetersToMicrometers(
        fabric.metersController.text,
      );
      return sum + (value ?? 0);
    });
    final modelCode =
        modelCodeOverride?.trim() ?? modelCodeController.text.trim();
    final modelDescription =
        modelDescriptionOverride?.trim() ?? descriptionController.text.trim();
    return ProjectDocument(
      id: id,
      orderName: modelCode.isNotEmpty
          ? modelCode
          : modelDescription.isNotEmpty
          ? modelDescription
          : 'Modelo sem identificação',
      modelCode: modelCode,
      modelDescription: modelDescription,
      desiredQuantityText: desiredQuantityController.text.trim(),
      fabricText: totalFabric == 0
          ? ''
          : BrazilianNumber.metersFromMicrometers(totalFabric),
      overlapText: overlapController.text.trim(),
      notes: notesController.text.trim(),
      sizes: sizes
          .map(
            (size) => SizeDraftData(
              id: size.id,
              name: size.nameController.text.trim(),
              percentageText: size.percentageController.text.trim(),
              blockId: size.blockId,
            ),
          )
          .toList(growable: false),
      blocks: blocks
          .map(
            (block) => BlockDraftData(
              id: block.id,
              name: block.name,
              lengthText: block.lengthText,
            ),
          )
          .toList(growable: false),
      fabricColors: fabricColors
          .map(
            (fabric) => FabricColorDraftData(
              id: fabric.id,
              colorName: fabric.colorNameController.text.trim(),
              metersText: fabric.metersController.text.trim(),
            ),
          )
          .toList(growable: false),
      result: resultOverride ?? result,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  EditableSize _createEditableSize({
    required String id,
    required String name,
    required String percentage,
    required String? blockId,
  }) => EditableSize(
    id: id,
    name: name,
    percentage: percentage,
    blockId: blockId,
    onChanged: _handleSizeChanged,
  );

  void _handleSizeChanged() {
    _markDirty();
    _automaticGroupingTimer?.cancel();
    _automaticGroupingTimer = Timer(const Duration(milliseconds: 450), () {
      if (_suppressDirty) {
        return;
      }
      _synchronizeBlocksByPercentage();
      _markDirty();
    });
  }

  void _synchronizeBlocksByPercentage() {
    final groupedSizes = <String, List<EditableSize>>{};
    final percentages = <String, double>{};

    for (final size in sizes) {
      final percentage = BrazilianNumber.tryParse(
        size.percentageController.text,
      );
      if (percentage == null || percentage <= 0) {
        continue;
      }
      final key = percentage.toStringAsFixed(6);
      percentages[key] = percentage;
      groupedSizes.putIfAbsent(key, () => <EditableSize>[]).add(size);
    }

    final existingById = <String, EditableBlock>{
      for (final block in blocks) block.id: block,
    };
    final claimedBlockIds = <String>{};

    for (final entry in groupedSizes.entries) {
      final candidates = entry.value
          .map((size) => existingById[size.blockId])
          .whereType<EditableBlock>()
          .where((block) => !claimedBlockIds.contains(block.id))
          .toList();
      candidates.sort((a, b) {
        final aHasLength = a.lengthText.trim().isNotEmpty ? 1 : 0;
        final bHasLength = b.lengthText.trim().isNotEmpty ? 1 : 0;
        return bHasLength.compareTo(aHasLength);
      });

      final selected =
          candidates.firstOrNull ??
          EditableBlock(
            id: IdGenerator.create('bloco'),
            name: '',
            lengthText: '',
          );
      final generatedName = _automaticBlockName(
        entry.value,
        percentages[entry.key]!,
      );
      final synchronized = EditableBlock(
        id: selected.id,
        name: generatedName,
        lengthText: selected.lengthText,
      );
      final existingIndex = blocks.indexWhere(
        (block) => block.id == synchronized.id,
      );
      if (existingIndex < 0) {
        blocks.add(synchronized);
      } else {
        blocks[existingIndex] = synchronized;
      }
      for (final size in entry.value) {
        size.blockId = synchronized.id;
      }
      claimedBlockIds.add(synchronized.id);
    }

    final referencedBlockIds = sizes
        .map((size) => size.blockId)
        .whereType<String>()
        .toSet();
    blocks.removeWhere((block) => !referencedBlockIds.contains(block.id));
    if (selectedBlockId != null &&
        !blocks.any((block) => block.id == selectedBlockId)) {
      selectedBlockId = null;
    }
  }

  String _automaticBlockName(
    List<EditableSize> groupedSizes,
    double percentage,
  ) {
    final names = groupedSizes
        .map((size) => size.nameController.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isNotEmpty) {
      return names.join('/');
    }
    final decimals = percentage == percentage.truncateToDouble() ? 0 : 2;
    return 'Bloco ${BrazilianNumber.decimal(percentage, decimals: decimals)}%';
  }

  String _uniqueBlockName(String base) {
    final existing = blocks.map((block) => block.name.toUpperCase()).toSet();
    var name = base;
    var counter = 2;
    while (existing.contains(name.toUpperCase())) {
      name = '$base $counter';
      counter++;
    }
    return name;
  }

  String _uniqueSizeName(String base) {
    final existing = sizes
        .map((size) => size.nameController.text.toUpperCase())
        .toSet();
    var name = base;
    var counter = 2;
    while (existing.contains(name.toUpperCase())) {
      name = '$base $counter';
      counter++;
    }
    return name;
  }

  void _markDirty() {
    if (_suppressDirty) {
      return;
    }
    isDirty = true;
    result = null;
    notifyListeners();
  }

  void _withoutDirty(VoidCallback action) {
    _suppressDirty = true;
    try {
      action();
    } finally {
      _suppressDirty = false;
    }
  }

  void _clearCollections() {
    _automaticGroupingTimer?.cancel();
    _automaticGroupingTimer = null;
    for (final size in sizes) {
      size.dispose();
    }
    for (final fabric in fabricColors) {
      fabric.dispose();
    }
    sizes.clear();
    blocks.clear();
    fabricColors.clear();
  }

  @override
  void dispose() {
    for (final controller in _mainControllers) {
      controller.dispose();
    }
    _clearCollections();
    super.dispose();
  }
}
