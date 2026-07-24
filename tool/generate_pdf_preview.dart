import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/reports/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera a prévia visual da ordem de corte', () async {
    final calculatedAt = DateTime(2026, 7, 23, 16, 30);
    const sizes = <SizeDraftData>[
      SizeDraftData(id: 'pp', name: 'PP', percentageText: '15', blockId: 'pp'),
      SizeDraftData(id: 'p', name: 'P', percentageText: '50', blockId: 'pgg2'),
      SizeDraftData(id: 'm', name: 'M', percentageText: '100', blockId: 'mgg1'),
      SizeDraftData(id: 'g', name: 'G', percentageText: '100', blockId: 'mgg1'),
      SizeDraftData(
        id: 'gg',
        name: 'GG',
        percentageText: '50',
        blockId: 'pgg2',
      ),
      SizeDraftData(
        id: 'g1',
        name: 'G1',
        percentageText: '100',
        blockId: 'mgg1',
      ),
      SizeDraftData(
        id: 'g2',
        name: 'G2',
        percentageText: '50',
        blockId: 'pgg2',
      ),
    ];
    const blocks = <BlockDraftData>[
      BlockDraftData(id: 'mgg1', name: 'M/G/G1', lengthText: '5,35'),
      BlockDraftData(id: 'pgg2', name: 'P/GG/G2', lengthText: '4,38'),
      BlockDraftData(id: 'pp', name: 'PP', lengthText: '2,40'),
    ];
    final project = ProjectDocument(
      id: 'preview',
      orderName: 'ORDEM 001',
      modelCode: 'MOD-001',
      modelDescription: 'MODELO DE TESTE',
      desiredQuantityText: '250',
      fabricText: '115',
      overlapText: '4',
      notes: 'Conferir enfesto antes do início do corte.',
      sizes: sizes,
      blocks: blocks,
      result: CalculationResult(
        availableMicrometers: 115000000,
        usedMicrometers: 111280000,
        overlapMicrometers: 40000,
        blocks: _previewBlocks(14, 7, 2),
        fabricColors: <FabricColorResult>[
          FabricColorResult(
            colorId: 'azul',
            colorName: 'Azul',
            availableMicrometers: 40000000,
            usedMicrometers: 38230000,
            blocks: _previewBlocks(5, 2, 1),
          ),
          FabricColorResult(
            colorId: 'preto',
            colorName: 'Preto',
            availableMicrometers: 44000000,
            usedMicrometers: 42650000,
            blocks: _previewBlocks(5, 3, 1),
          ),
          FabricColorResult(
            colorId: 'rosa',
            colorName: 'Rosa',
            availableMicrometers: 31000000,
            usedMicrometers: 30400000,
            blocks: _previewBlocks(4, 2, 0),
          ),
        ],
        sizes: const <SizeAllocation>[
          SizeAllocation(
            sizeName: 'PP',
            quantity: 2,
            desiredPercentage: 15,
            achievedPercentage: 14.29,
            consumptionPerPieceMicrometers: 2440000,
          ),
          SizeAllocation(
            sizeName: 'P',
            quantity: 7,
            desiredPercentage: 50,
            achievedPercentage: 50,
            consumptionPerPieceMicrometers: 1473333,
          ),
          SizeAllocation(
            sizeName: 'M',
            quantity: 14,
            desiredPercentage: 100,
            achievedPercentage: 100,
            consumptionPerPieceMicrometers: 1796667,
          ),
          SizeAllocation(
            sizeName: 'G',
            quantity: 14,
            desiredPercentage: 100,
            achievedPercentage: 100,
            consumptionPerPieceMicrometers: 1796667,
          ),
          SizeAllocation(
            sizeName: 'GG',
            quantity: 7,
            desiredPercentage: 50,
            achievedPercentage: 50,
            consumptionPerPieceMicrometers: 1473333,
          ),
          SizeAllocation(
            sizeName: 'G1',
            quantity: 14,
            desiredPercentage: 100,
            achievedPercentage: 100,
            consumptionPerPieceMicrometers: 1796667,
          ),
          SizeAllocation(
            sizeName: 'G2',
            quantity: 7,
            desiredPercentage: 50,
            achievedPercentage: 50,
            consumptionPerPieceMicrometers: 1473333,
          ),
        ],
        calculatedAt: calculatedAt,
      ),
      createdAt: calculatedAt,
      updatedAt: calculatedAt,
    );

    final outputDirectory = Directory('output/pdf');
    await outputDirectory.create(recursive: true);
    final output = File('${outputDirectory.path}/ordem_corte_preview.pdf');
    await output.writeAsBytes(
      await const PdfReportService().generate(project),
      flush: true,
    );
    stdout.writeln(output.absolute.path);
  });
}

List<BlockAllocation> _previewBlocks(int main, int secondary, int pp) =>
    <BlockAllocation>[
      BlockAllocation(
        blockId: 'mgg1',
        blockName: 'M/G/G1',
        sizeNames: const <String>['M', 'G', 'G1'],
        desiredPercentage: 100,
        originalLengthMicrometers: 5350000,
        overlapMicrometers: 40000,
        quantity: main,
      ),
      BlockAllocation(
        blockId: 'pgg2',
        blockName: 'P/GG/G2',
        sizeNames: const <String>['P', 'GG', 'G2'],
        desiredPercentage: 50,
        originalLengthMicrometers: 4380000,
        overlapMicrometers: 40000,
        quantity: secondary,
      ),
      BlockAllocation(
        blockId: 'pp',
        blockName: 'PP',
        sizeNames: const <String>['PP'],
        desiredPercentage: 15,
        originalLengthMicrometers: 2400000,
        overlapMicrometers: 40000,
        quantity: pp,
      ),
    ];
