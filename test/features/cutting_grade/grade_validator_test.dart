import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/cutting_grade/domain/services/grade_validator.dart';

void main() {
  const validator = GradeValidator();

  CalculationInput input({
    List<GradeSize>? sizes,
    List<CuttingBlock>? blocks,
  }) => CalculationInput(
    availableMicrometers: 100000000,
    overlapMicrometers: 40000,
    sizes:
        sizes ??
        const <GradeSize>[
          GradeSize(
            id: 'm',
            name: 'M',
            desiredPercentage: 100,
            blockId: 'bloco',
          ),
        ],
    blocks:
        blocks ??
        const <CuttingBlock>[
          CuttingBlock(id: 'bloco', name: 'M', lengthMicrometers: 5000000),
        ],
  );

  test('rejeita porcentagens diferentes no mesmo bloco', () {
    final issues = validator.validate(
      input(
        sizes: const <GradeSize>[
          GradeSize(
            id: 'm',
            name: 'M',
            desiredPercentage: 100,
            blockId: 'bloco',
          ),
          GradeSize(
            id: 'g',
            name: 'G',
            desiredPercentage: 80,
            blockId: 'bloco',
          ),
        ],
      ),
    );

    expect(
      issues.any((issue) => issue.message.contains('porcentagens diferentes')),
      isTrue,
    );
    expect(issues.single.message, contains('M, G'));
  });

  test('rejeita tamanho sem bloco', () {
    final issues = validator.validate(
      input(
        sizes: const <GradeSize>[
          GradeSize(id: 'm', name: 'M', desiredPercentage: 100, blockId: null),
        ],
      ),
    );

    expect(
      issues.any((issue) => issue.message.contains('associado a um bloco')),
      isTrue,
    );
  });

  test('rejeita bloco sem tamanho', () {
    final issues = validator.validate(
      input(
        blocks: const <CuttingBlock>[
          CuttingBlock(id: 'bloco', name: 'M', lengthMicrometers: 5000000),
          CuttingBlock(id: 'vazio', name: 'Vazio', lengthMicrometers: 3000000),
        ],
      ),
    );

    expect(
      issues.any(
        (issue) =>
            issue.message.contains('"Vazio"') &&
            issue.message.contains('pelo menos um tamanho'),
      ),
      isTrue,
    );
  });

  test('rejeita nomes duplicados sem diferenciar maiúsculas', () {
    final issues = validator.validate(
      input(
        sizes: const <GradeSize>[
          GradeSize(
            id: '1',
            name: 'G1',
            desiredPercentage: 100,
            blockId: 'bloco',
          ),
          GradeSize(
            id: '2',
            name: 'g1',
            desiredPercentage: 100,
            blockId: 'bloco',
          ),
        ],
      ),
    );

    expect(issues.any((issue) => issue.message.contains('duplicados')), isTrue);
  });
}
