import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';

class ValidationIssue {
  const ValidationIssue(this.message);
  final String message;
}

class GradeValidator {
  const GradeValidator();

  List<ValidationIssue> validate(CalculationInput input) {
    final issues = <ValidationIssue>[];
    if (input.availableMicrometers <= 0) {
      issues.add(
        const ValidationIssue(
          'A quantidade total de tecido deve ser maior que zero.',
        ),
      );
    }
    if (input.fabricColors.isNotEmpty) {
      _validateDuplicateNames(
        input.fabricColors.map((item) => item.colorName),
        'cor',
        issues,
      );
      for (final fabric in input.fabricColors) {
        if (fabric.colorName.trim().isEmpty) {
          issues.add(
            const ValidationIssue('Todas as cores precisam ter um nome.'),
          );
        }
        if (fabric.availableMicrometers <= 0) {
          issues.add(
            ValidationIssue(
              'A metragem da cor "${fabric.colorName}" deve ser maior que zero.',
            ),
          );
        }
      }
    }
    if (input.overlapMicrometers < 0) {
      issues.add(
        const ValidationIssue('A margem de traspasso não pode ser negativa.'),
      );
    }
    if (input.sizes.isEmpty) {
      issues.add(const ValidationIssue('Adicione pelo menos um tamanho.'));
    }
    if (input.blocks.isEmpty) {
      issues.add(const ValidationIssue('Adicione pelo menos um bloco.'));
    }

    _validateDuplicateNames(
      input.sizes.map((item) => item.name),
      'tamanho',
      issues,
    );
    _validateDuplicateNames(
      input.blocks.map((item) => item.name),
      'bloco',
      issues,
    );

    final blockIds = input.blocks.map((item) => item.id).toSet();
    for (final size in input.sizes) {
      if (size.name.trim().isEmpty) {
        issues.add(
          const ValidationIssue('Todos os tamanhos precisam ter um nome.'),
        );
      }
      if (size.desiredPercentage <= 0) {
        issues.add(
          ValidationIssue(
            'A porcentagem do tamanho "${size.name}" deve ser maior que zero.',
          ),
        );
      }
      if (size.blockId == null || !blockIds.contains(size.blockId)) {
        issues.add(
          ValidationIssue(
            'O tamanho "${size.name}" precisa estar associado a um bloco.',
          ),
        );
      }
    }

    for (final block in input.blocks) {
      if (block.name.trim().isEmpty) {
        issues.add(
          const ValidationIssue('Todos os blocos precisam ter um nome.'),
        );
      }
      if (block.lengthMicrometers <= 0) {
        issues.add(
          ValidationIssue(
            'O comprimento do bloco "${block.name}" deve ser maior que zero.',
          ),
        );
      }
      final blockSizes = input.sizes
          .where((size) => size.blockId == block.id)
          .toList();
      if (blockSizes.isEmpty) {
        issues.add(
          ValidationIssue(
            'O bloco "${block.name}" precisa conter pelo menos um tamanho.',
          ),
        );
        continue;
      }
      final reference = blockSizes.first.desiredPercentage;
      final inconsistent = blockSizes
          .where(
            (size) => (size.desiredPercentage - reference).abs() > 0.000001,
          )
          .map((size) => size.name)
          .toList();
      if (inconsistent.isNotEmpty) {
        final allNames = blockSizes.map((size) => size.name).join(', ');
        issues.add(
          ValidationIssue(
            'Os tamanhos do bloco "${block.name}" têm porcentagens diferentes '
            '($allNames). Nesta versão, todos precisam usar a mesma porcentagem.',
          ),
        );
      }
    }
    return issues;
  }

  void _validateDuplicateNames(
    Iterable<String> names,
    String type,
    List<ValidationIssue> issues,
  ) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final name in names) {
      final normalized = name.trim().toUpperCase();
      if (normalized.isNotEmpty && !seen.add(normalized)) {
        duplicates.add(name.trim());
      }
    }
    if (duplicates.isNotEmpty) {
      issues.add(
        ValidationIssue(
          'Não são permitidos nomes de $type duplicados: '
          '${duplicates.join(', ')}.',
        ),
      );
    }
  }
}
