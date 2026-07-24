import 'dart:isolate';
import 'dart:math';

import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/cutting_grade/domain/services/grade_validator.dart';

class GradeCalculator {
  const GradeCalculator({this.validator = const GradeValidator()});

  final GradeValidator validator;
  static const double _epsilon = 0.0000001;
  static const double _maximumAllowedPercentageDifference = 5;

  CalculationResult? calculate(CalculationInput input) {
    final issues = validator.validate(input);
    if (issues.isNotEmpty) {
      throw ArgumentError(issues.map((issue) => issue.message).join('\n'));
    }

    final fabrics = input.fabricColors.isEmpty
        ? <FabricColorInput>[
            FabricColorInput(
              id: 'tecido',
              colorName: 'Tecido',
              availableMicrometers: input.availableMicrometers,
            ),
          ]
        : input.fabricColors;
    final maxDesired = input.sizes
        .map((size) => size.desiredPercentage)
        .reduce(max);
    final colorResults = <FabricColorResult>[];
    final groupedQuantities = <String, int>{
      for (final block in input.blocks) block.id: 0,
    };
    var totalUsed = 0;

    for (final fabric in fabrics) {
      final single = _calculateSingle(input, fabric.availableMicrometers);
      final quantities =
          single?.quantities ?? List<int>.filled(input.blocks.length, 0);
      final blocks = _buildBlockAllocations(input, quantities);
      for (var index = 0; index < input.blocks.length; index++) {
        final blockId = input.blocks[index].id;
        groupedQuantities[blockId] =
            groupedQuantities[blockId]! + quantities[index];
      }
      final used = single?.used ?? 0;
      totalUsed += used;
      colorResults.add(
        FabricColorResult(
          colorId: fabric.id,
          colorName: fabric.colorName,
          availableMicrometers: fabric.availableMicrometers,
          usedMicrometers: used,
          blocks: blocks,
        ),
      );
    }

    if (totalUsed <= 0) {
      return null;
    }

    final grouped = input.blocks
        .map((block) => groupedQuantities[block.id]!)
        .toList(growable: false);
    final allocations = _buildBlockAllocations(input, grouped);
    final maximumQuantity = grouped.reduce(max);
    final sizeAllocations = <SizeAllocation>[];
    for (var index = 0; index < input.blocks.length; index++) {
      final block = input.blocks[index];
      final blockSizes = input.sizes
          .where((size) => size.blockId == block.id)
          .toList(growable: false);
      final quantity = grouped[index];
      final effectiveLength =
          block.lengthMicrometers + input.overlapMicrometers;
      for (final size in blockSizes) {
        sizeAllocations.add(
          SizeAllocation(
            sizeName: size.name,
            quantity: quantity,
            desiredPercentage: size.desiredPercentage,
            achievedPercentage: maximumQuantity == 0
                ? 0
                : quantity * maxDesired / maximumQuantity,
            consumptionPerPieceMicrometers:
                (effectiveLength / blockSizes.length).round(),
          ),
        );
      }
    }

    final totalAvailable = fabrics.fold(
      0,
      (sum, fabric) => sum + fabric.availableMicrometers,
    );
    return CalculationResult(
      availableMicrometers: totalAvailable,
      usedMicrometers: totalUsed,
      overlapMicrometers: input.overlapMicrometers,
      blocks: allocations,
      sizes: sizeAllocations,
      fabricColors: colorResults,
      calculatedAt: DateTime.now(),
    );
  }

  _SingleCalculation? _calculateSingle(
    CalculationInput input,
    int availableMicrometers,
  ) {
    final blockData = input.blocks
        .map((block) {
          final sizes = input.sizes
              .where((size) => size.blockId == block.id)
              .toList();
          return _BlockData(
            block: block,
            sizes: sizes,
            desiredPercentage: sizes.first.desiredPercentage,
            effectiveLength: block.lengthMicrometers + input.overlapMicrometers,
          );
        })
        .toList(growable: false);

    final maxDesired = blockData
        .map((item) => item.desiredPercentage)
        .reduce(max);
    final normalized = blockData
        .map((item) => item.desiredPercentage * 100 / maxDesired)
        .toList(growable: false);
    final minLength = blockData.map((item) => item.effectiveLength).reduce(min);
    final maximumReference = availableMicrometers ~/ minLength;
    if (maximumReference <= 0) {
      return null;
    }

    final normalizedTolerance = min(
      100.0,
      _maximumAllowedPercentageDifference * 100 / maxDesired,
    );
    final utilizationCandidate = _findHighestUtilizationCandidate(
      availableMicrometers,
      blockData,
      normalized,
      normalizedTolerance,
      maximumReference,
    );
    if (utilizationCandidate != null) {
      final completed = _completeCandidateUtilization(
        utilizationCandidate,
        availableMicrometers,
        blockData,
        normalized,
      );
      return _SingleCalculation(
        quantities: List<int>.of(completed.quantities),
        used: completed.used,
      );
    }

    final initialCandidate = _findInitialCandidate(
      availableMicrometers,
      blockData,
      normalized,
      maximumReference,
    );
    if (initialCandidate == null) {
      return null;
    }
    var best = initialCandidate;

    // Branch and bound: para cada quantidade de referência, apenas faixas que
    // podem empatar ou melhorar o maior erro atual são visitadas. Ramos que
    // excedem tecido, maior erro ou soma de erros são descartados cedo.
    for (var reference = 1; reference <= maximumReference; reference++) {
      final ranges = <List<int>>[];
      var possible = true;
      for (var index = 0; index < blockData.length; index++) {
        final ratio = normalized[index];
        final maxError = best.maxError + _epsilon;
        final lower = max(0, ((ratio - maxError) * reference / 100).ceil());
        final upper = min(
          reference,
          ((ratio + maxError) * reference / 100).floor(),
        );
        if (lower > upper) {
          possible = false;
          break;
        }
        final values = List<int>.generate(
          upper - lower + 1,
          (offset) => lower + offset,
        );
        values.sort((left, right) {
          final leftError = (left * 100 / reference - normalized[index]).abs();
          final rightError = (right * 100 / reference - normalized[index])
              .abs();
          return leftError.compareTo(rightError);
        });
        ranges.add(values);
      }
      if (!possible) {
        continue;
      }

      void search(
        int index,
        List<int> quantities,
        int used,
        double partialMaxError,
        double partialSumError,
        int totalSheets,
        bool hasReference,
      ) {
        if (used > availableMicrometers ||
            partialMaxError > best.maxError + _epsilon ||
            (partialMaxError >= best.maxError - _epsilon &&
                partialSumError > best.sumError + _epsilon)) {
          return;
        }
        if (index == blockData.length) {
          if (!hasReference || totalSheets == 0) {
            return;
          }
          final candidate = _Candidate(
            quantities: List<int>.of(quantities),
            used: used,
            maxError: partialMaxError,
            sumError: partialSumError,
            totalSheets: totalSheets,
          );
          if (candidate.isBetterThan(best)) {
            best = candidate;
          }
          return;
        }

        for (final quantity in ranges[index]) {
          final error = (quantity * 100 / reference - normalized[index]).abs();
          quantities.add(quantity);
          search(
            index + 1,
            quantities,
            used + quantity * blockData[index].effectiveLength,
            max(partialMaxError, error),
            partialSumError + error * blockData[index].sizes.length,
            totalSheets + quantity,
            hasReference || quantity == reference,
          );
          quantities.removeLast();
        }
      }

      search(0, <int>[], 0, 0, 0, 0, false);
    }

    best = _completeCandidateUtilization(
      best,
      availableMicrometers,
      blockData,
      normalized,
    );
    final maximumQuantity = best.quantities.reduce(max);
    if (maximumQuantity <= 0 || best.used > availableMicrometers) {
      return null;
    }
    return _SingleCalculation(
      quantities: List<int>.of(best.quantities),
      used: best.used,
    );
  }

  List<BlockAllocation> _buildBlockAllocations(
    CalculationInput input,
    List<int> quantities,
  ) {
    final allocations = <BlockAllocation>[];
    for (var index = 0; index < input.blocks.length; index++) {
      final block = input.blocks[index];
      final sizes = input.sizes
          .where((size) => size.blockId == block.id)
          .toList(growable: false);
      allocations.add(
        BlockAllocation(
          blockId: block.id,
          blockName: block.name,
          sizeNames: sizes.map((size) => size.name).toList(growable: false),
          desiredPercentage: sizes.first.desiredPercentage,
          originalLengthMicrometers: block.lengthMicrometers,
          overlapMicrometers: input.overlapMicrometers,
          quantity: quantities[index],
        ),
      );
    }
    return allocations;
  }

  _Candidate? _findHighestUtilizationCandidate(
    int available,
    List<_BlockData> blocks,
    List<double> normalized,
    double normalizedTolerance,
    int maximumReference,
  ) {
    _Candidate? best;

    for (var reference = 1; reference <= maximumReference; reference++) {
      final ranges = <List<int>>[];
      var minimumUsed = 0;
      var possible = true;

      for (var index = 0; index < blocks.length; index++) {
        final ratio = normalized[index];
        final lower = max(
          0,
          ((ratio - normalizedTolerance) * reference / 100 - _epsilon).ceil(),
        );
        final upper = min(
          reference,
          ((ratio + normalizedTolerance) * reference / 100 + _epsilon).floor(),
        );
        if (lower > upper) {
          possible = false;
          break;
        }
        minimumUsed += lower * blocks[index].effectiveLength;
        ranges.add(
          List<int>.generate(upper - lower + 1, (offset) => upper - offset),
        );
      }

      if (!possible) {
        continue;
      }
      if (minimumUsed > available) {
        break;
      }

      final suffixMinimumUsed = List<int>.filled(blocks.length + 1, 0);
      final suffixMaximumUsed = List<int>.filled(blocks.length + 1, 0);
      for (var index = blocks.length - 1; index >= 0; index--) {
        suffixMinimumUsed[index] =
            suffixMinimumUsed[index + 1] +
            ranges[index].last * blocks[index].effectiveLength;
        suffixMaximumUsed[index] =
            suffixMaximumUsed[index + 1] +
            ranges[index].first * blocks[index].effectiveLength;
      }

      void search(
        int index,
        List<int> quantities,
        int used,
        double partialMaxError,
        double partialSumError,
        int totalSheets,
        bool hasReference,
      ) {
        if (used > available || used + suffixMinimumUsed[index] > available) {
          return;
        }
        if (best != null && used + suffixMaximumUsed[index] < best!.used) {
          return;
        }
        if (index == blocks.length) {
          if (!hasReference || totalSheets == 0) {
            return;
          }
          final candidate = _Candidate(
            quantities: List<int>.of(quantities),
            used: used,
            maxError: partialMaxError,
            sumError: partialSumError,
            totalSheets: totalSheets,
          );
          if (best == null || candidate.isBetterForUtilizationThan(best!)) {
            best = candidate;
          }
          return;
        }

        for (final quantity in ranges[index]) {
          final error = (quantity * 100 / reference - normalized[index]).abs();
          quantities.add(quantity);
          search(
            index + 1,
            quantities,
            used + quantity * blocks[index].effectiveLength,
            max(partialMaxError, error),
            partialSumError + error * blocks[index].sizes.length,
            totalSheets + quantity,
            hasReference || quantity == reference,
          );
          quantities.removeLast();
        }
      }

      search(0, <int>[], 0, 0, 0, 0, false);
    }

    return best;
  }

  _Candidate _candidateFromQuantities(
    List<_BlockData> blocks,
    List<double> normalized,
    List<int> quantities,
  ) {
    final reference = quantities.reduce(max);
    var maximumError = 0.0;
    var errorSum = 0.0;
    for (var index = 0; index < quantities.length; index++) {
      final error = (quantities[index] * 100 / reference - normalized[index])
          .abs();
      maximumError = max(maximumError, error);
      errorSum += error * blocks[index].sizes.length;
    }
    return _Candidate(
      quantities: List<int>.of(quantities),
      used: _consumption(blocks, quantities),
      maxError: maximumError,
      sumError: errorSum,
      totalSheets: quantities.fold(0, (sum, quantity) => sum + quantity),
    );
  }

  _Candidate _completeCandidateUtilization(
    _Candidate candidate,
    int available,
    List<_BlockData> blocks,
    List<double> normalized,
  ) {
    var best = candidate;
    while (true) {
      _Candidate? next;
      for (var index = 0; index < blocks.length; index++) {
        if (best.used + blocks[index].effectiveLength > available) {
          continue;
        }
        final quantities = List<int>.of(best.quantities);
        quantities[index]++;
        final option = _candidateFromQuantities(blocks, normalized, quantities);
        if (next == null || option.isBetterThan(next)) {
          next = option;
        }
      }
      if (next == null) {
        return best;
      }
      best = next;
    }
  }

  _Candidate? _findInitialCandidate(
    int available,
    List<_BlockData> blocks,
    List<double> normalized,
    int maximumReference,
  ) {
    _Candidate? best;
    for (var reference = 1; reference <= maximumReference; reference++) {
      final quantities = List<int>.generate(
        blocks.length,
        (index) => (reference * normalized[index] / 100).round(),
      );
      var used = _consumption(blocks, quantities);
      while (used > available) {
        var selected = -1;
        var bestPenalty = double.infinity;
        for (var index = 0; index < quantities.length; index++) {
          if (quantities[index] <= 0) {
            continue;
          }
          final currentError =
              (quantities[index] * 100 / reference - normalized[index]).abs();
          final nextError =
              ((quantities[index] - 1) * 100 / reference - normalized[index])
                  .abs();
          final penalty =
              (nextError - currentError) / blocks[index].effectiveLength;
          if (penalty < bestPenalty) {
            bestPenalty = penalty;
            selected = index;
          }
        }
        if (selected < 0) {
          break;
        }
        quantities[selected]--;
        used -= blocks[selected].effectiveLength;
      }
      final actualMaximum = quantities.reduce(max);
      if (actualMaximum <= 0 || used > available) {
        continue;
      }
      var maxError = 0.0;
      var sumError = 0.0;
      for (var index = 0; index < quantities.length; index++) {
        final error =
            (quantities[index] * 100 / actualMaximum - normalized[index]).abs();
        maxError = max(maxError, error);
        sumError += error * blocks[index].sizes.length;
      }
      final candidate = _Candidate(
        quantities: List<int>.of(quantities),
        used: used,
        maxError: maxError,
        sumError: sumError,
        totalSheets: quantities.fold(0, (sum, item) => sum + item),
      );
      if (best == null || candidate.isBetterThan(best)) {
        best = candidate;
      }
    }
    return best;
  }

  int _consumption(List<_BlockData> blocks, List<int> quantities) {
    var total = 0;
    for (var index = 0; index < blocks.length; index++) {
      total += blocks[index].effectiveLength * quantities[index];
    }
    return total;
  }
}

Future<CalculationResult?> calculateGradeAsync(CalculationInput input) =>
    Isolate.run(() => const GradeCalculator().calculate(input));

class _BlockData {
  const _BlockData({
    required this.block,
    required this.sizes,
    required this.desiredPercentage,
    required this.effectiveLength,
  });

  final CuttingBlock block;
  final List<GradeSize> sizes;
  final double desiredPercentage;
  final int effectiveLength;
}

class _SingleCalculation {
  const _SingleCalculation({required this.quantities, required this.used});

  final List<int> quantities;
  final int used;
}

class _Candidate {
  const _Candidate({
    required this.quantities,
    required this.used,
    required this.maxError,
    required this.sumError,
    required this.totalSheets,
  });

  final List<int> quantities;
  final int used;
  final double maxError;
  final double sumError;
  final int totalSheets;

  bool isBetterForUtilizationThan(_Candidate other) {
    const epsilon = 0.0000001;
    if (used != other.used) {
      return used > other.used;
    }
    if ((maxError - other.maxError).abs() > epsilon) {
      return maxError < other.maxError;
    }
    if ((sumError - other.sumError).abs() > epsilon) {
      return sumError < other.sumError;
    }
    return totalSheets < other.totalSheets;
  }

  bool isBetterThan(_Candidate other) {
    const epsilon = 0.0000001;
    if ((maxError - other.maxError).abs() > epsilon) {
      return maxError < other.maxError;
    }
    if (used != other.used) {
      return used > other.used;
    }
    if ((sumError - other.sumError).abs() > epsilon) {
      return sumError < other.sumError;
    }
    return totalSheets < other.totalSheets;
  }
}
