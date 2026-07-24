import 'dart:math';

class GradeSize {
  const GradeSize({
    required this.id,
    required this.name,
    required this.desiredPercentage,
    required this.blockId,
  });

  final String id;
  final String name;
  final double desiredPercentage;
  final String? blockId;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'desiredPercentage': desiredPercentage,
    'blockId': blockId,
  };

  factory GradeSize.fromJson(Map<String, Object?> json) => GradeSize(
    id: json['id']! as String,
    name: json['name']! as String,
    desiredPercentage: (json['desiredPercentage']! as num).toDouble(),
    blockId: json['blockId'] as String?,
  );
}

class CuttingBlock {
  const CuttingBlock({
    required this.id,
    required this.name,
    required this.lengthMicrometers,
  });

  final String id;
  final String name;
  final int lengthMicrometers;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'lengthMicrometers': lengthMicrometers,
  };

  factory CuttingBlock.fromJson(Map<String, Object?> json) => CuttingBlock(
    id: json['id']! as String,
    name: json['name']! as String,
    lengthMicrometers: json['lengthMicrometers']! as int,
  );
}

class FabricColorInput {
  const FabricColorInput({
    required this.id,
    required this.colorName,
    required this.availableMicrometers,
  });

  final String id;
  final String colorName;
  final int availableMicrometers;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'colorName': colorName,
    'availableMicrometers': availableMicrometers,
  };

  factory FabricColorInput.fromJson(Map<String, Object?> json) =>
      FabricColorInput(
        id: json['id']! as String,
        colorName: json['colorName']! as String,
        availableMicrometers: json['availableMicrometers']! as int,
      );
}

class CalculationInput {
  const CalculationInput({
    required this.availableMicrometers,
    required this.overlapMicrometers,
    required this.sizes,
    required this.blocks,
    this.fabricColors = const <FabricColorInput>[],
  });

  final int availableMicrometers;
  final int overlapMicrometers;
  final List<GradeSize> sizes;
  final List<CuttingBlock> blocks;
  final List<FabricColorInput> fabricColors;

  Map<String, Object?> toJson() => <String, Object?>{
    'availableMicrometers': availableMicrometers,
    'overlapMicrometers': overlapMicrometers,
    'sizes': sizes.map((item) => item.toJson()).toList(),
    'blocks': blocks.map((item) => item.toJson()).toList(),
    'fabricColors': fabricColors.map((item) => item.toJson()).toList(),
  };

  factory CalculationInput.fromJson(Map<String, Object?> json) =>
      CalculationInput(
        availableMicrometers: json['availableMicrometers']! as int,
        overlapMicrometers: json['overlapMicrometers']! as int,
        sizes: (json['sizes']! as List<Object?>)
            .map((item) => GradeSize.fromJson(item! as Map<String, Object?>))
            .toList(growable: false),
        blocks: (json['blocks']! as List<Object?>)
            .map((item) => CuttingBlock.fromJson(item! as Map<String, Object?>))
            .toList(growable: false),
        fabricColors:
            (json['fabricColors'] as List<Object?>?)
                ?.map(
                  (item) =>
                      FabricColorInput.fromJson(item! as Map<String, Object?>),
                )
                .toList(growable: false) ??
            const <FabricColorInput>[],
      );
}

class BlockAllocation {
  const BlockAllocation({
    required this.blockId,
    required this.blockName,
    required this.sizeNames,
    required this.desiredPercentage,
    required this.originalLengthMicrometers,
    required this.overlapMicrometers,
    required this.quantity,
  });

  final String blockId;
  final String blockName;
  final List<String> sizeNames;
  final double desiredPercentage;
  final int originalLengthMicrometers;
  final int overlapMicrometers;
  final int quantity;

  int get effectiveLengthMicrometers =>
      originalLengthMicrometers + overlapMicrometers;
  int get consumptionMicrometers => effectiveLengthMicrometers * quantity;

  Map<String, Object?> toJson() => <String, Object?>{
    'blockId': blockId,
    'blockName': blockName,
    'sizeNames': sizeNames,
    'desiredPercentage': desiredPercentage,
    'originalLengthMicrometers': originalLengthMicrometers,
    'overlapMicrometers': overlapMicrometers,
    'quantity': quantity,
  };

  factory BlockAllocation.fromJson(Map<String, Object?> json) =>
      BlockAllocation(
        blockId: json['blockId']! as String,
        blockName: json['blockName']! as String,
        sizeNames: (json['sizeNames']! as List<Object?>).cast<String>(),
        desiredPercentage: (json['desiredPercentage']! as num).toDouble(),
        originalLengthMicrometers: json['originalLengthMicrometers']! as int,
        overlapMicrometers: json['overlapMicrometers']! as int,
        quantity: json['quantity']! as int,
      );
}

enum AllocationStatus {
  exact('Exato'),
  veryClose('Muito próximo'),
  withinTolerance('Dentro da tolerância'),
  outsideTolerance('Fora da tolerância');

  const AllocationStatus(this.label);
  final String label;

  static AllocationStatus fromDifference(double difference) {
    final absolute = difference.abs();
    if (absolute < 0.005) {
      return AllocationStatus.exact;
    }
    if (absolute <= 1) {
      return AllocationStatus.veryClose;
    }
    if (absolute <= 5) {
      return AllocationStatus.withinTolerance;
    }
    return AllocationStatus.outsideTolerance;
  }
}

class SizeAllocation {
  const SizeAllocation({
    required this.sizeName,
    required this.quantity,
    required this.desiredPercentage,
    required this.achievedPercentage,
    this.consumptionPerPieceMicrometers = 0,
  });

  final String sizeName;
  final int quantity;
  final double desiredPercentage;
  final double achievedPercentage;
  final int consumptionPerPieceMicrometers;

  double get difference => achievedPercentage - desiredPercentage;
  AllocationStatus get status => AllocationStatus.fromDifference(difference);
  int get totalConsumptionMicrometers =>
      consumptionPerPieceMicrometers * quantity;

  Map<String, Object?> toJson() => <String, Object?>{
    'sizeName': sizeName,
    'quantity': quantity,
    'desiredPercentage': desiredPercentage,
    'achievedPercentage': achievedPercentage,
    'consumptionPerPieceMicrometers': consumptionPerPieceMicrometers,
  };

  factory SizeAllocation.fromJson(
    Map<String, Object?> json, {
    int fallbackConsumptionPerPieceMicrometers = 0,
  }) => SizeAllocation(
    sizeName: json['sizeName']! as String,
    quantity: json['quantity']! as int,
    desiredPercentage: (json['desiredPercentage']! as num).toDouble(),
    achievedPercentage: (json['achievedPercentage']! as num).toDouble(),
    consumptionPerPieceMicrometers:
        (json['consumptionPerPieceMicrometers'] as num?)?.round() ??
        fallbackConsumptionPerPieceMicrometers,
  );
}

class FabricColorResult {
  const FabricColorResult({
    required this.colorId,
    required this.colorName,
    required this.availableMicrometers,
    required this.usedMicrometers,
    required this.blocks,
  });

  final String colorId;
  final String colorName;
  final int availableMicrometers;
  final int usedMicrometers;
  final List<BlockAllocation> blocks;

  int get remainingMicrometers =>
      max(0, availableMicrometers - usedMicrometers);
  int get totalSheets =>
      blocks.fold(0, (total, allocation) => total + allocation.quantity);
  double get utilizationPercentage => availableMicrometers == 0
      ? 0
      : usedMicrometers * 100 / availableMicrometers;

  Map<String, Object?> toJson() => <String, Object?>{
    'colorId': colorId,
    'colorName': colorName,
    'availableMicrometers': availableMicrometers,
    'usedMicrometers': usedMicrometers,
    'blocks': blocks.map((item) => item.toJson()).toList(),
  };

  factory FabricColorResult.fromJson(Map<String, Object?> json) =>
      FabricColorResult(
        colorId: json['colorId']! as String,
        colorName: json['colorName']! as String,
        availableMicrometers: json['availableMicrometers']! as int,
        usedMicrometers: json['usedMicrometers']! as int,
        blocks: (json['blocks']! as List<Object?>)
            .map(
              (item) => BlockAllocation.fromJson(item! as Map<String, Object?>),
            )
            .toList(growable: false),
      );
}

class CalculationResult {
  const CalculationResult({
    required this.availableMicrometers,
    required this.usedMicrometers,
    required this.overlapMicrometers,
    required this.blocks,
    required this.sizes,
    required this.calculatedAt,
    this.fabricColors = const <FabricColorResult>[],
  });

  final int availableMicrometers;
  final int usedMicrometers;
  final int overlapMicrometers;
  final List<BlockAllocation> blocks;
  final List<SizeAllocation> sizes;
  final DateTime calculatedAt;
  final List<FabricColorResult> fabricColors;

  int get remainingMicrometers =>
      max(0, availableMicrometers - usedMicrometers);
  int get totalSheets =>
      blocks.fold(0, (total, allocation) => total + allocation.quantity);
  int get totalPieces =>
      sizes.fold(0, (total, allocation) => total + allocation.quantity);
  int get averageConsumptionPerPieceMicrometers =>
      totalPieces == 0 ? 0 : (usedMicrometers / totalPieces).round();
  double get utilizationPercentage => availableMicrometers == 0
      ? 0
      : usedMicrometers * 100 / availableMicrometers;

  Map<String, Object?> toJson() => <String, Object?>{
    'availableMicrometers': availableMicrometers,
    'usedMicrometers': usedMicrometers,
    'overlapMicrometers': overlapMicrometers,
    'blocks': blocks.map((item) => item.toJson()).toList(),
    'sizes': sizes.map((item) => item.toJson()).toList(),
    'fabricColors': fabricColors.map((item) => item.toJson()).toList(),
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  factory CalculationResult.fromJson(Map<String, Object?> json) {
    final blocks = (json['blocks']! as List<Object?>)
        .map((item) => BlockAllocation.fromJson(item! as Map<String, Object?>))
        .toList(growable: false);
    final sizes = (json['sizes']! as List<Object?>)
        .map((item) {
          final sizeJson = item! as Map<String, Object?>;
          final sizeName = sizeJson['sizeName']! as String;
          final matchingBlocks = blocks.where(
            (block) => block.sizeNames.contains(sizeName),
          );
          final fallback = matchingBlocks.isEmpty
              ? 0
              : (matchingBlocks.first.effectiveLengthMicrometers /
                        matchingBlocks.first.sizeNames.length)
                    .round();
          return SizeAllocation.fromJson(
            sizeJson,
            fallbackConsumptionPerPieceMicrometers: fallback,
          );
        })
        .toList(growable: false);
    final availableMicrometers = json['availableMicrometers']! as int;
    final usedMicrometers = json['usedMicrometers']! as int;
    final parsedFabricColors =
        (json['fabricColors'] as List<Object?>?)
            ?.map(
              (item) =>
                  FabricColorResult.fromJson(item! as Map<String, Object?>),
            )
            .toList(growable: false) ??
        const <FabricColorResult>[];
    final fabricColors = parsedFabricColors.isNotEmpty
        ? parsedFabricColors
        : <FabricColorResult>[
            FabricColorResult(
              colorId: 'tecido',
              colorName: 'Tecido',
              availableMicrometers: availableMicrometers,
              usedMicrometers: usedMicrometers,
              blocks: blocks,
            ),
          ];
    return CalculationResult(
      availableMicrometers: availableMicrometers,
      usedMicrometers: usedMicrometers,
      overlapMicrometers: json['overlapMicrometers']! as int,
      blocks: blocks,
      sizes: sizes,
      fabricColors: fabricColors,
      calculatedAt: DateTime.parse(json['calculatedAt']! as String),
    );
  }
}
