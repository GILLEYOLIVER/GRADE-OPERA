import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/reports/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera relatório PDF válido para um cálculo', () async {
    final now = DateTime(2026, 7, 23, 10, 30);
    final project = ProjectDocument(
      id: 'teste',
      orderName: 'Teste PDF',
      modelCode: 'MOD-1',
      modelDescription: 'Modelo de teste',
      desiredQuantityText: '250',
      fabricText: '10',
      overlapText: '4',
      notes: 'Conferido.',
      sizes: const <SizeDraftData>[],
      blocks: const <BlockDraftData>[],
      result: CalculationResult(
        availableMicrometers: 10000000,
        usedMicrometers: 5040000,
        overlapMicrometers: 40000,
        blocks: const <BlockAllocation>[
          BlockAllocation(
            blockId: 'b',
            blockName: 'M',
            sizeNames: <String>['M'],
            desiredPercentage: 100,
            originalLengthMicrometers: 5000000,
            overlapMicrometers: 40000,
            quantity: 1,
          ),
        ],
        sizes: const <SizeAllocation>[
          SizeAllocation(
            sizeName: 'M',
            quantity: 1,
            desiredPercentage: 100,
            achievedPercentage: 100,
          ),
        ],
        calculatedAt: now,
      ),
      createdAt: now,
      updatedAt: now,
    );

    final bytes = await const PdfReportService().generate(project);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
