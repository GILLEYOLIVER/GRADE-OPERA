import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/app/grade_opera_app.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/cutting_grade/presentation/controllers/grade_controller.dart';
import 'package:grade_opera/features/cutting_grade/presentation/pages/grade_main_page.dart';
import 'package:grade_opera/features/cutting_grade/presentation/widgets/results_panel.dart';

import '../../support/in_memory_project_repository.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1400, 1000),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GradeOperaApp(repository: InMemoryProjectRepository()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('adiciona tamanho e define o comprimento do bloco automático', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('adicionar-tamanho')));
    await tester.pumpAndSettle();
    expect(find.text('Ex.: M, G2 ou 42'), findsWidgets);

    final lengthField = find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField &&
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value).startsWith(
            'comprimento-bloco-',
          ),
    );
    await tester.ensureVisible(lengthField);
    await tester.enterText(lengthField, '5,20');
    await tester.pump();

    expect(find.text('5,20'), findsOneWidget);
  });

  testWidgets('desktop mostra os campos principais no painel compacto', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('painel-compacto')), findsOneWidget);
    expect(find.byKey(const Key('campo-ordem')), findsNothing);
    expect(find.byKey(const Key('campo-codigo-modelo')), findsOneWidget);
    expect(find.byKey(const Key('campo-descricao-modelo')), findsOneWidget);
    expect(find.byKey(const Key('campo-quantidade-desejada')), findsOneWidget);
    expect(find.byKey(const Key('campo-tecido')), findsOneWidget);
    expect(find.byKey(const Key('campo-margem')), findsOneWidget);
    expect(find.byKey(const Key('adicionar-cor')), findsOneWidget);
    final calculate = find.byKey(const Key('calcular-distribuicao'));
    expect(calculate, findsOneWidget);
    expect(tester.getBottomRight(calculate).dy, lessThan(1000));
    expect(tester.takeException(), isNull);
  });

  testWidgets('salvar como preserva o projeto original e cria uma nova cópia', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = InMemoryProjectRepository();
    final controller = GradeController(repository: repository);
    addTearDown(controller.dispose);
    controller.modelCodeController.text = 'MODELO-ORIGINAL';
    controller.descriptionController.text = 'Descrição original';
    await controller.saveProject();
    final originalId = controller.projectId;

    await tester.pumpWidget(
      MaterialApp(home: GradeMainPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('salvar-como')));
    await tester.pumpAndSettle();
    expect(find.text('Salvar projeto como'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('salvar-como-codigo')),
      'MODELO-COPIA',
    );
    await tester.enterText(
      find.byKey(const Key('salvar-como-descricao')),
      'Descrição da cópia',
    );
    await tester.tap(find.byKey(const Key('confirmar-salvar-como')));
    await tester.pumpAndSettle();

    expect(repository.projects, hasLength(2));
    expect(repository.projects.last.id, originalId);
    expect(repository.projects.last.modelCode, 'MODELO-ORIGINAL');
    expect(repository.projects.first.id, isNot(originalId));
    expect(repository.projects.first.modelCode, 'MODELO-COPIA');
    expect(repository.projects.first.modelDescription, 'Descrição da cópia');
    expect(controller.projectId, repository.projects.first.id);
    expect(controller.isDirty, isFalse);
    expect(find.textContaining('O projeto original foi preservado'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adiciona uma nova cor com metragem independente', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('adicionar-cor')));
    await tester.pumpAndSettle();

    expect(find.text('Cor 2'), findsOneWidget);
    expect(find.text('Metragem *'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('várias cores ficam em uma lista com rolagem sem sobreposição', (
    tester,
  ) async {
    await pumpApp(tester);

    for (var index = 0; index < 6; index++) {
      final addColor = find.byKey(const Key('adicionar-cor'));
      await tester.ensureVisible(addColor);
      await tester.tap(addColor);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barra-rolagem-cores')), findsOneWidget);
    final scrollable = find.descendant(
      of: find.byKey(const Key('lista-cores-rolavel')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(scrollable, findsOneWidget);
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'blocos usam altura natural e tecidos recebem o espaço restante',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = GradeController(
        repository: InMemoryProjectRepository(),
        startWithStandardGrade: false,
      );
      addTearDown(controller.dispose);
      controller.overlapController.text = '4';
      for (var index = 0; index < 4; index++) {
        controller.addSize(
          name: 'T${index + 1}',
          percentage: '${100 - (index * 10)}',
        );
      }
      for (final block in controller.blocks) {
        controller.updateBlockLength(block.id, '4,20');
      }
      for (var index = 0; index < 5; index++) {
        controller.addFabricColor();
      }

      await tester.pumpWidget(
        MaterialApp(home: GradeMainPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      final blocksSection = find.byKey(const Key('secao-blocos'));
      final fabricsSection = find.byKey(const Key('secao-tecidos'));
      expect(blocksSection, findsOneWidget);
      expect(fabricsSection, findsOneWidget);
      expect(
        tester.getSize(blocksSection).height,
        lessThan(tester.getSize(fabricsSection).height),
      );
      expect(
        tester.getBottomLeft(blocksSection).dy,
        lessThan(tester.getTopLeft(fabricsSection).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tabelas compactas de resultado rolam sem invadir umas às outras',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final blocks = List<BlockAllocation>.generate(
        4,
        (index) => BlockAllocation(
          blockId: 'b$index',
          blockName: 'Bloco ${index + 1}',
          sizeNames: <String>['T${index + 1}'],
          desiredPercentage: 100,
          originalLengthMicrometers: 2500000,
          overlapMicrometers: 40000,
          quantity: 10,
        ),
      );
      final colors = List<FabricColorResult>.generate(
        6,
        (index) => FabricColorResult(
          colorId: 'c$index',
          colorName: 'Cor ${index + 1}',
          availableMicrometers: 100000000,
          usedMicrometers: 90000000,
          blocks: blocks,
        ),
      );
      final result = CalculationResult(
        availableMicrometers: 600000000,
        usedMicrometers: 540000000,
        overlapMicrometers: 40000,
        blocks: blocks,
        sizes: List<SizeAllocation>.generate(
          12,
          (index) => SizeAllocation(
            sizeName: 'T${index + 1}',
            quantity: 10,
            desiredPercentage: 100,
            achievedPercentage: 100,
            consumptionPerPieceMicrometers: 2500000,
          ),
        ),
        fabricColors: colors,
        calculatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactResultsPanel(
              result: result,
              onBack: () {},
              onPdf: () {},
              onPrint: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final colorScrollbar = find.byKey(
        const Key('barra-vertical-Fios por cor'),
      );
      expect(colorScrollbar, findsOneWidget);
      final verticalScrollable = find.descendant(
        of: colorScrollbar,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(verticalScrollable, findsOneWidget);
      final scrollState = tester.state<ScrollableState>(verticalScrollable);
      expect(scrollState.position.maxScrollExtent, greaterThan(0));
      expect(
        find.byKey(const Key('barra-vertical-Quantidade agrupada')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('barra-vertical-Peças por tamanho')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('agrupa automaticamente tamanhos com porcentagens iguais', () {
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      startWithStandardGrade: false,
    );
    addTearDown(controller.dispose);

    controller.addSize(name: 'M', percentage: '100');
    controller.addSize(name: 'G', percentage: '100');
    controller.addSize(name: 'P', percentage: '50');
    controller.addSize(name: 'GG', percentage: '50');
    controller.addSize(name: 'PP', percentage: '15');

    expect(controller.blocks, hasLength(3));
    expect(controller.blocks.map((block) => block.name), <String>[
      'M/G',
      'P/GG',
      'PP',
    ]);
    expect(controller.sizes[0].blockId, controller.sizes[1].blockId);
    expect(controller.sizes[2].blockId, controller.sizes[3].blockId);
    expect(controller.sizes[4].blockId, isNot(controller.sizes[3].blockId));
    expect(controller.themeMode, ThemeMode.light);
  });

  test('inicia com a grade padrão completa e não cria duplicatas', () {
    final controller = GradeController(repository: InMemoryProjectRepository());
    addTearDown(controller.dispose);

    controller.addStandardSizes();

    expect(controller.sizes.map((size) => size.nameController.text), <String>[
      'PP',
      'P',
      'M',
      'G',
      'GG',
      'G1',
      'G2',
    ]);
  });

  test('mantém o comprimento ao mesclar novos tamanhos no bloco', () {
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      startWithStandardGrade: false,
    );
    addTearDown(controller.dispose);

    controller.addSize(name: 'M', percentage: '100');
    final blockId = controller.blocks.single.id;
    controller.updateBlockLength(blockId, '5,20');
    controller.addSize(name: 'G', percentage: '100');

    expect(controller.blocks, hasLength(1));
    expect(controller.blocks.single.id, blockId);
    expect(controller.blocks.single.name, 'M/G');
    expect(controller.blocks.single.lengthText, '5,20');
  });

  test('reagrupa automaticamente depois de alterar uma porcentagem', () async {
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      startWithStandardGrade: false,
    );
    addTearDown(controller.dispose);

    controller.addSize(name: 'M', percentage: '100');
    controller.addSize(name: 'P', percentage: '50');
    expect(controller.blocks, hasLength(2));

    controller.sizes[1].percentageController.text = '100';
    await Future<void>.delayed(const Duration(milliseconds: 550));

    expect(controller.blocks, hasLength(1));
    expect(controller.blocks.single.name, 'M/P');
    expect(controller.sizes[0].blockId, controller.sizes[1].blockId);
  });

  test('usa comprimento de cada bloco e uma margem global em centímetros', () {
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      startWithStandardGrade: false,
    );
    addTearDown(controller.dispose);
    controller.fabricController.text = '80';
    controller.overlapController.text = '4';

    controller.addSize(name: 'M', percentage: '100');
    controller.addSize(name: 'G', percentage: '100');
    controller.addSize(name: 'GG', percentage: '100');
    controller.addSize(name: 'P', percentage: '50');
    controller.addSize(name: 'G2', percentage: '50');
    controller.updateBlockLength(
      controller.blocks.firstWhere((block) => block.name == 'M/G/GG').id,
      '5,35',
    );
    controller.updateBlockLength(
      controller.blocks.firstWhere((block) => block.name == 'P/G2').id,
      '4,38',
    );

    final input = controller.buildCalculationInput();
    expect(input.availableMicrometers, 80000000);
    expect(input.overlapMicrometers, 40000);
    expect(
      input.blocks
          .firstWhere((block) => block.name == 'M/G/GG')
          .lengthMicrometers,
      5350000,
    );
    expect(
      input.blocks
          .firstWhere((block) => block.name == 'P/G2')
          .lengthMicrometers,
      4380000,
    );
  });

  test('soma as metragens sem perder a separação por cor', () {
    final controller = GradeController(
      repository: InMemoryProjectRepository(),
      startWithStandardGrade: false,
    );
    addTearDown(controller.dispose);
    controller.fabricColors.first.colorNameController.text = 'Preto';
    controller.fabricController.text = '40';
    controller.addFabricColor(name: 'Branco', metersText: '25,5');
    controller.overlapController.text = '4';

    final input = controller.buildCalculationInput();

    expect(input.availableMicrometers, 65500000);
    expect(input.fabricColors, hasLength(2));
    expect(input.fabricColors.first.colorName, 'Preto');
    expect(input.fabricColors.last.availableMicrometers, 25500000);
  });

  testWidgets('carrega exemplo, calcula e mostra o resultado real', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('carregar-exemplo')));
    await tester.pumpAndSettle();
    expect(find.text('M/G'), findsWidgets);
    expect(find.text('P/GG'), findsWidgets);

    final calculate = find.byKey(const Key('calcular-distribuicao'));
    await tester.ensureVisible(calculate);
    await tester.tap(calculate);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('painel-resultados')), findsOneWidget);
    expect(find.textContaining('114,71'), findsWidgets);
    expect(find.textContaining('0,29'), findsWidgets);
  });

  testWidgets('limpa formulário com confirmação', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('carregar-exemplo')));
    await tester.pumpAndSettle();

    final clear = find.byKey(const Key('limpar-formulario'));
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('Limpar formulário?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
    await tester.pumpAndSettle();

    final codeField = tester.widget<TextFormField>(
      find.byKey(const Key('campo-codigo-modelo')),
    );
    expect(codeField.controller!.text, isEmpty);
  });

  testWidgets('valida campos obrigatórios antes do cálculo', (tester) async {
    await pumpApp(tester);

    final calculate = find.byKey(const Key('calcular-distribuicao'));
    await tester.ensureVisible(calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo-ordem')), findsNothing);
    expect(find.text('Informe um número válido.'), findsNWidgets(3));
  });
}
