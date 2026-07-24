import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/projects/services/project_file_exporter.dart';

void main() {
  test('salva uma cópia individual na pasta escolhida', () async {
    final directory = await Directory.systemTemp.createTemp(
      'grade_opera_export_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final now = DateTime(2026, 7, 24);
    final project = ProjectDocument(
      id: 'projeto-1',
      orderName: '6422',
      modelCode: '6422',
      modelDescription: 'Vestido teste',
      desiredQuantityText: '450',
      fabricText: '900',
      overlapText: '4',
      notes: '',
      sizes: const <SizeDraftData>[],
      blocks: const <BlockDraftData>[],
      result: null,
      createdAt: now,
      updatedAt: now,
    );
    const exporter = LocalProjectFileExporter();

    final firstPath = await exporter.exportProject(
      project,
      directoryPath: directory.path,
    );
    final secondPath = await exporter.exportProject(
      project,
      directoryPath: directory.path,
    );

    expect(firstPath, endsWith('GRADE_OPERA_6422.gradeopera.json'));
    expect(secondPath, endsWith('GRADE_OPERA_6422 (2).gradeopera.json'));
    final content =
        jsonDecode(await File(firstPath).readAsString())
            as Map<String, Object?>;
    expect(content['application'], 'GRADE OPERA');
    expect(content['schemaVersion'], 1);
    final exportedProject = content['project']! as Map<String, Object?>;
    expect(exportedProject['id'], 'projeto-1');
    expect(exportedProject['modelCode'], '6422');
    expect(exportedProject['modelDescription'], 'Vestido teste');
  });
}
