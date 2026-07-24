import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';

class SizeDraftData {
  const SizeDraftData({
    required this.id,
    required this.name,
    required this.percentageText,
    required this.blockId,
  });

  final String id;
  final String name;
  final String percentageText;
  final String? blockId;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'percentageText': percentageText,
    'blockId': blockId,
  };

  factory SizeDraftData.fromJson(Map<String, Object?> json) => SizeDraftData(
    id: json['id']! as String,
    name: json['name']! as String,
    percentageText: json['percentageText']! as String,
    blockId: json['blockId'] as String?,
  );
}

class BlockDraftData {
  const BlockDraftData({
    required this.id,
    required this.name,
    required this.lengthText,
  });

  final String id;
  final String name;
  final String lengthText;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'lengthText': lengthText,
  };

  factory BlockDraftData.fromJson(Map<String, Object?> json) => BlockDraftData(
    id: json['id']! as String,
    name: json['name']! as String,
    lengthText: json['lengthText']! as String,
  );
}

class FabricColorDraftData {
  const FabricColorDraftData({
    required this.id,
    required this.colorName,
    required this.metersText,
  });

  final String id;
  final String colorName;
  final String metersText;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'colorName': colorName,
    'metersText': metersText,
  };

  factory FabricColorDraftData.fromJson(Map<String, Object?> json) =>
      FabricColorDraftData(
        id: json['id']! as String,
        colorName: json['colorName']! as String,
        metersText: json['metersText']! as String,
      );
}

class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.orderName,
    required this.modelCode,
    required this.modelDescription,
    this.desiredQuantityText = '',
    required this.fabricText,
    required this.overlapText,
    required this.notes,
    required this.sizes,
    required this.blocks,
    required this.result,
    required this.createdAt,
    required this.updatedAt,
    this.fabricColors = const <FabricColorDraftData>[],
  });

  final String id;
  final String orderName;
  final String modelCode;
  final String modelDescription;
  final String desiredQuantityText;
  final String fabricText;
  final String overlapText;
  final String notes;
  final List<SizeDraftData> sizes;
  final List<BlockDraftData> blocks;
  final CalculationResult? result;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FabricColorDraftData> fabricColors;

  ProjectDocument copyWith({
    String? id,
    String? orderName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProjectDocument(
    id: id ?? this.id,
    orderName: orderName ?? this.orderName,
    modelCode: modelCode,
    modelDescription: modelDescription,
    desiredQuantityText: desiredQuantityText,
    fabricText: fabricText,
    overlapText: overlapText,
    notes: notes,
    sizes: sizes,
    blocks: blocks,
    result: result,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    fabricColors: fabricColors,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'orderName': orderName,
    'modelCode': modelCode,
    'modelDescription': modelDescription,
    'desiredQuantityText': desiredQuantityText,
    'fabricText': fabricText,
    'overlapText': overlapText,
    'notes': notes,
    'sizes': sizes.map((item) => item.toJson()).toList(),
    'blocks': blocks.map((item) => item.toJson()).toList(),
    'fabricColors': fabricColors.map((item) => item.toJson()).toList(),
    'result': result?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ProjectDocument.fromJson(
    Map<String, Object?> json,
  ) => ProjectDocument(
    id: json['id']! as String,
    orderName: json['orderName']! as String,
    modelCode: json['modelCode']! as String,
    modelDescription: json['modelDescription']! as String,
    desiredQuantityText: json['desiredQuantityText'] as String? ?? '',
    fabricText: json['fabricText']! as String,
    overlapText: json['overlapText']! as String,
    notes: json['notes']! as String,
    sizes: (json['sizes']! as List<Object?>)
        .map((item) => SizeDraftData.fromJson(item! as Map<String, Object?>))
        .toList(growable: false),
    blocks: (json['blocks']! as List<Object?>)
        .map((item) => BlockDraftData.fromJson(item! as Map<String, Object?>))
        .toList(growable: false),
    fabricColors:
        (json['fabricColors'] as List<Object?>?)
            ?.map(
              (item) =>
                  FabricColorDraftData.fromJson(item! as Map<String, Object?>),
            )
            .toList(growable: false) ??
        const <FabricColorDraftData>[],
    result: json['result'] == null
        ? null
        : CalculationResult.fromJson(json['result']! as Map<String, Object?>),
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );
}
