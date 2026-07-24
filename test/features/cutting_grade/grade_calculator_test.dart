import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/cutting_grade/domain/services/grade_calculator.dart';

void main() {
  const calculator = GradeCalculator();

  group('operações de consumo', () {
    test('soma a margem ao comprimento do bloco', () {
      const allocation = BlockAllocation(
        blockId: 'b',
        blockName: 'Bloco',
        sizeNames: <String>['M'],
        desiredPercentage: 100,
        originalLengthMicrometers: 5200000,
        overlapMicrometers: 40000,
        quantity: 14,
      );

      expect(allocation.effectiveLengthMicrometers, 5240000);
    });

    test('calcula o consumo por bloco', () {
      const allocation = BlockAllocation(
        blockId: 'b',
        blockName: 'Bloco',
        sizeNames: <String>['M'],
        desiredPercentage: 100,
        originalLengthMicrometers: 5200000,
        overlapMicrometers: 40000,
        quantity: 14,
      );

      expect(allocation.consumptionMicrometers, 73360000);
    });

    test('calcula consumo total e sobra', () {
      final result = CalculationResult(
        availableMicrometers: 115000000,
        usedMicrometers: 114710000,
        overlapMicrometers: 40000,
        blocks: const <BlockAllocation>[],
        sizes: const <SizeAllocation>[],
        calculatedAt: DateTime(2026),
      );

      expect(result.usedMicrometers, 114710000);
      expect(result.remainingMicrometers, 290000);
    });

    test(
      'calcula consumo médio somente com tecido usado e peças produzidas',
      () {
        final result = CalculationResult(
          availableMicrometers: 915000000,
          usedMicrometers: 900000000,
          overlapMicrometers: 0,
          blocks: const <BlockAllocation>[],
          sizes: const <SizeAllocation>[
            SizeAllocation(
              sizeName: 'M',
              quantity: 300,
              desiredPercentage: 100,
              achievedPercentage: 100,
            ),
            SizeAllocation(
              sizeName: 'G',
              quantity: 150,
              desiredPercentage: 50,
              achievedPercentage: 50,
            ),
          ],
          calculatedAt: DateTime(2026),
        );

        expect(result.totalPieces, 450);
        expect(result.remainingMicrometers, 15000000);
        expect(result.averageConsumptionPerPieceMicrometers, 2000000);
      },
    );
  });

  test('mantém os percentuais desejados informados pelo usuário', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 100000000,
        overlapMicrometers: 0,
        sizes: <GradeSize>[
          GradeSize(id: 'a', name: 'A', desiredPercentage: 80, blockId: 'a'),
          GradeSize(id: 'b', name: 'B', desiredPercentage: 40, blockId: 'b'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'a', name: 'A', lengthMicrometers: 1000000),
          CuttingBlock(id: 'b', name: 'B', lengthMicrometers: 1000000),
        ],
      ),
    );

    expect(result, isNotNull);
    expect(result!.sizes.first.desiredPercentage, 80);
    expect(result.sizes.last.desiredPercentage, 40);
    expect(result.sizes.first.achievedPercentage, 80);
    expect(result.sizes.last.achievedPercentage, closeTo(39.402985, 0.000001));
    expect(result.usedMicrometers, 100000000);
    expect(result.remainingMicrometers, 0);
  });

  test('mantém percentuais desejados e alcançados acima de 100%', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 30000000,
        overlapMicrometers: 0,
        sizes: <GradeSize>[
          GradeSize(id: 'a', name: 'A', desiredPercentage: 200, blockId: 'a'),
          GradeSize(id: 'b', name: 'B', desiredPercentage: 100, blockId: 'b'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'a', name: 'A', lengthMicrometers: 1000000),
          CuttingBlock(id: 'b', name: 'B', lengthMicrometers: 1000000),
        ],
      ),
    );

    expect(result, isNotNull);
    expect(result!.sizes.first.desiredPercentage, 200);
    expect(result.sizes.first.achievedPercentage, 200);
    expect(result.sizes.last.desiredPercentage, 100);
    expect(result.sizes.last.achievedPercentage, 100);
  });

  test('calcula cada cor separadamente e agrupa as quantidades', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 20000000,
        overlapMicrometers: 0,
        fabricColors: <FabricColorInput>[
          FabricColorInput(
            id: 'preto',
            colorName: 'Preto',
            availableMicrometers: 12000000,
          ),
          FabricColorInput(
            id: 'branco',
            colorName: 'Branco',
            availableMicrometers: 8000000,
          ),
        ],
        sizes: <GradeSize>[
          GradeSize(id: 'm', name: 'M', desiredPercentage: 100, blockId: 'm'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'm', name: 'M', lengthMicrometers: 1000000),
        ],
      ),
    );

    expect(result, isNotNull);
    expect(result!.fabricColors, hasLength(2));
    expect(result.fabricColors[0].blocks.single.quantity, 12);
    expect(result.fabricColors[1].blocks.single.quantity, 8);
    expect(result.blocks.single.quantity, 20);
    expect(result.totalSheets, 20);
  });

  test('não permite consumo acima do tecido disponível', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 1000000,
        overlapMicrometers: 40000,
        sizes: <GradeSize>[
          GradeSize(
            id: 'm',
            name: 'M',
            desiredPercentage: 100,
            blockId: 'bloco',
          ),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'bloco', name: 'M', lengthMicrometers: 5200000),
        ],
      ),
    );

    expect(result, isNull);
  });

  test('caso real de 115 metros retorna 14, 7 e 2 folhas', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 115000000,
        overlapMicrometers: 40000,
        sizes: <GradeSize>[
          GradeSize(id: 'm', name: 'M', desiredPercentage: 100, blockId: 'mg'),
          GradeSize(id: 'g', name: 'G', desiredPercentage: 100, blockId: 'mg'),
          GradeSize(id: 'p', name: 'P', desiredPercentage: 50, blockId: 'pgg'),
          GradeSize(
            id: 'gg',
            name: 'GG',
            desiredPercentage: 50,
            blockId: 'pgg',
          ),
          GradeSize(id: 'pp', name: 'PP', desiredPercentage: 15, blockId: 'pp'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'mg', name: 'M/G', lengthMicrometers: 5200000),
          CuttingBlock(id: 'pgg', name: 'P/GG', lengthMicrometers: 5170000),
          CuttingBlock(id: 'pp', name: 'PP', lengthMicrometers: 2400000),
        ],
      ),
    );

    expect(result, isNotNull);
    final quantities = <String, int>{
      for (final block in result!.blocks) block.blockName: block.quantity,
    };
    expect(quantities['M/G'], 14);
    expect(quantities['P/GG'], 7);
    expect(quantities['PP'], 2);
    expect(result.usedMicrometers, 114710000);
    expect(result.remainingMicrometers, 290000);
    expect(result.usedMicrometers, lessThanOrEqualTo(115000000));
  });

  test('calcula peças por tamanho e consumo médio por peça', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 10780000,
        overlapMicrometers: 40000,
        sizes: <GradeSize>[
          GradeSize(id: 'm', name: 'M', desiredPercentage: 100, blockId: 'b'),
          GradeSize(id: 'g', name: 'G', desiredPercentage: 100, blockId: 'b'),
          GradeSize(id: 'gg', name: 'GG', desiredPercentage: 100, blockId: 'b'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'b', name: 'M/G/GG', lengthMicrometers: 5350000),
        ],
      ),
    );

    expect(result, isNotNull);
    expect(result!.blocks.single.quantity, 2);
    expect(result.totalPieces, 6);
    expect(result.sizes.map((size) => size.quantity), everyElement(2));
    expect(
      result.sizes.map((size) => size.consumptionPerPieceMicrometers),
      everyElement(1796667),
    );
  });

  test('aproveita a sobra quando ainda cabe outro bloco', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 80000000,
        overlapMicrometers: 40000,
        sizes: <GradeSize>[
          GradeSize(id: 'pp', name: 'PP', desiredPercentage: 10, blockId: 'pp'),
          GradeSize(id: 'p', name: 'P', desiredPercentage: 11, blockId: 'p-g2'),
          GradeSize(
            id: 'g2',
            name: 'G2',
            desiredPercentage: 11,
            blockId: 'p-g2',
          ),
          GradeSize(
            id: 'm',
            name: 'M',
            desiredPercentage: 150,
            blockId: 'm-g-gg',
          ),
          GradeSize(
            id: 'g',
            name: 'G',
            desiredPercentage: 150,
            blockId: 'm-g-gg',
          ),
          GradeSize(
            id: 'gg',
            name: 'GG',
            desiredPercentage: 150,
            blockId: 'm-g-gg',
          ),
          GradeSize(id: 'g1', name: 'G1', desiredPercentage: 50, blockId: 'g1'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'pp', name: 'PP', lengthMicrometers: 3000000),
          CuttingBlock(id: 'p-g2', name: 'P/G2', lengthMicrometers: 2560000),
          CuttingBlock(
            id: 'm-g-gg',
            name: 'M/G/GG',
            lengthMicrometers: 4560000,
          ),
          CuttingBlock(id: 'g1', name: 'G1', lengthMicrometers: 2000000),
        ],
      ),
    );

    expect(result, isNotNull);
    expect(result!.blocks.map((block) => block.quantity), <int>[1, 1, 14, 4]);
    expect(result.usedMicrometers, 78200000);
    expect(result.remainingMicrometers, 1800000);
    expect(result.remainingMicrometers, lessThan(2040000));
  });

  test('usa o tecido de cada cor mantendo a distribuição desejada', () {
    final result = calculator.calculate(
      const CalculationInput(
        availableMicrometers: 577000000,
        overlapMicrometers: 60000,
        fabricColors: <FabricColorInput>[
          FabricColorInput(
            id: 'telha',
            colorName: 'TELHA',
            availableMicrometers: 172000000,
          ),
          FabricColorInput(
            id: 'royal',
            colorName: 'ROYAL',
            availableMicrometers: 118000000,
          ),
          FabricColorInput(
            id: 'oliva',
            colorName: 'OLIVA',
            availableMicrometers: 125000000,
          ),
          FabricColorInput(
            id: 'azul-claro',
            colorName: 'AZUL CLARO',
            availableMicrometers: 101000000,
          ),
          FabricColorInput(
            id: 'marcala',
            colorName: 'MARÇALA',
            availableMicrometers: 61000000,
          ),
        ],
        sizes: <GradeSize>[
          GradeSize(id: 'pp', name: 'PP', desiredPercentage: 15, blockId: 'pp'),
          GradeSize(id: 'p', name: 'P', desiredPercentage: 25, blockId: 'p-g2'),
          GradeSize(
            id: 'g2',
            name: 'G2',
            desiredPercentage: 25,
            blockId: 'p-g2',
          ),
          GradeSize(
            id: 'm',
            name: 'M',
            desiredPercentage: 100,
            blockId: 'm-g-gg',
          ),
          GradeSize(
            id: 'g',
            name: 'G',
            desiredPercentage: 100,
            blockId: 'm-g-gg',
          ),
          GradeSize(
            id: 'gg',
            name: 'GG',
            desiredPercentage: 100,
            blockId: 'm-g-gg',
          ),
          GradeSize(id: 'g1', name: 'G1', desiredPercentage: 50, blockId: 'g1'),
        ],
        blocks: <CuttingBlock>[
          CuttingBlock(id: 'pp', name: 'PP', lengthMicrometers: 2100000),
          CuttingBlock(id: 'p-g2', name: 'P/G2', lengthMicrometers: 4660000),
          CuttingBlock(
            id: 'm-g-gg',
            name: 'M/G/GG',
            lengthMicrometers: 6810000,
          ),
          CuttingBlock(id: 'g1', name: 'G1', lengthMicrometers: 2510000),
        ],
      ),
    );

    expect(result, isNotNull);
    final colors = <String, FabricColorResult>{
      for (final color in result!.fabricColors) color.colorName: color,
    };
    expect(colors['TELHA']!.blocks.map((block) => block.quantity), <int>[
      3,
      5,
      17,
      9,
    ]);
    expect(colors['TELHA']!.usedMicrometers, 170000000);
    expect(colors['TELHA']!.remainingMicrometers, 2000000);

    expect(colors['ROYAL']!.blocks.map((block) => block.quantity), <int>[
      2,
      3,
      12,
      6,
    ]);
    expect(colors['ROYAL']!.usedMicrometers, 116340000);
    expect(colors['ROYAL']!.remainingMicrometers, 1660000);

    expect(colors['OLIVA']!.blocks.map((block) => block.quantity), <int>[
      2,
      3,
      13,
      6,
    ]);
    expect(colors['OLIVA']!.usedMicrometers, 123210000);
    expect(colors['OLIVA']!.remainingMicrometers, 1790000);

    expect(colors['AZUL CLARO']!.blocks.map((block) => block.quantity), <int>[
      2,
      3,
      10,
      5,
    ]);
    expect(colors['AZUL CLARO']!.usedMicrometers, 100030000);
    expect(colors['AZUL CLARO']!.remainingMicrometers, 970000);

    expect(colors['MARÇALA']!.blocks.map((block) => block.quantity), <int>[
      1,
      2,
      6,
      3,
    ]);
    expect(colors['MARÇALA']!.usedMicrometers, 60530000);
    expect(colors['MARÇALA']!.remainingMicrometers, 470000);

    for (final color in result.fabricColors) {
      final blockConsumption = color.blocks.fold<int>(
        0,
        (sum, block) => sum + block.consumptionMicrometers,
      );
      expect(color.usedMicrometers, blockConsumption);
      expect(
        color.remainingMicrometers,
        color.availableMicrometers - blockConsumption,
      );
      expect(
        color.usedMicrometers,
        lessThanOrEqualTo(color.availableMicrometers),
      );
      expect(color.remainingMicrometers, lessThan(2160000));
    }

    expect(result.usedMicrometers, 570110000);
    expect(result.remainingMicrometers, 6890000);
    expect(
      result.usedMicrometers,
      result.fabricColors.fold<int>(
        0,
        (sum, color) => sum + color.usedMicrometers,
      ),
    );
  });
}
