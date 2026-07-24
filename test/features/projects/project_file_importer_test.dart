import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/features/projects/services/project_file_importer.dart';

void main() {
  group('LocalProjectFileImporter', () {
    late Directory directory;
    const importer = LocalProjectFileImporter();

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'grade_opera_import_',
      );
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('importa um arquivo .gradeopera.json válido', () async {
      final file = await _writeJson(directory, _validEnvelope());

      final project = await importer.importProject(file.path);

      expect(project.id, 'projeto-1');
      expect(project.modelCode, '6422');
      expect(project.modelDescription, 'Vestido teste');
      expect(project.desiredQuantityText, '450');
      expect(project.overlapText, '4');
      expect(project.notes, 'Observação de teste');
      expect(project.sizes.single.name, 'M');
      expect(project.blocks.single.lengthText, '5,20');
      expect(project.fabricColors.single.colorName, 'Preto');
      expect(project.fabricColors.single.metersText, '900');
    });

    test('rejeita uma extensão diferente', () async {
      final file = await _writeJson(
        directory,
        _validEnvelope(),
        name: 'projeto.json',
      );

      await expectLater(
        importer.importProject(file.path),
        throwsA(
          isA<ProjectFileImportException>().having(
            (error) => error.message,
            'message',
            contains('não é um projeto'),
          ),
        ),
      );
    });

    test('rejeita JSON inválido', () async {
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'invalido.gradeopera.json',
      );
      await file.writeAsString('{json inválido');

      await expectLater(
        importer.importProject(file.path),
        throwsA(
          isA<ProjectFileImportException>().having(
            (error) => error.message,
            'message',
            contains('corrompido'),
          ),
        ),
      );
    });

    test('rejeita raiz que não seja objeto', () async {
      final file = await _writeJson(directory, <Object?>[]);

      await expectLater(
        importer.importProject(file.path),
        throwsA(isA<ProjectFileImportException>()),
      );
    });

    test('rejeita application diferente', () async {
      final envelope = _validEnvelope()..['application'] = 'OUTRO APP';
      final file = await _writeJson(directory, envelope);

      await expectLater(
        importer.importProject(file.path),
        throwsA(
          isA<ProjectFileImportException>().having(
            (error) => error.message,
            'message',
            contains('não é um projeto'),
          ),
        ),
      );
    });

    test('rejeita ausência de project', () async {
      final envelope = _validEnvelope()..remove('project');
      final file = await _writeJson(directory, envelope);

      await expectLater(
        importer.importProject(file.path),
        throwsA(isA<ProjectFileImportException>()),
      );
    });

    test('rejeita project que não seja objeto', () async {
      final envelope = _validEnvelope()..['project'] = 'inválido';
      final file = await _writeJson(directory, envelope);

      await expectLater(
        importer.importProject(file.path),
        throwsA(isA<ProjectFileImportException>()),
      );
    });

    test('rejeita schemaVersion diferente de 1', () async {
      final envelope = _validEnvelope()..['schemaVersion'] = 2;
      final file = await _writeJson(directory, envelope);

      await expectLater(
        importer.importProject(file.path),
        throwsA(
          isA<ProjectFileImportException>().having(
            (error) => error.message,
            'message',
            contains('não é compatível'),
          ),
        ),
      );
    });

    test('rejeita arquivo inexistente', () async {
      final path =
          '${directory.path}${Platform.pathSeparator}'
          'ausente.gradeopera.json';

      await expectLater(
        importer.importProject(path),
        throwsA(
          isA<ProjectFileImportException>().having(
            (error) => error.message,
            'message',
            contains('não foi encontrado'),
          ),
        ),
      );
    });

    test('rejeita conteúdo de projeto incompatível', () async {
      final envelope = _validEnvelope()..['project'] = <String, Object?>{};
      final file = await _writeJson(directory, envelope);

      await expectLater(
        importer.importProject(file.path),
        throwsA(
          isA<ProjectFileImportException>().having(
            (error) => error.message,
            'message',
            contains('corrompido'),
          ),
        ),
      );
    });
  });
}

Future<File> _writeJson(
  Directory directory,
  Object? content, {
  String name = 'projeto.gradeopera.json',
}) async {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsString(jsonEncode(content));
  return file;
}

Map<String, Object?> _validEnvelope() => <String, Object?>{
  'schemaVersion': 1,
  'application': 'GRADE OPERA',
  'project': <String, Object?>{
    'id': 'projeto-1',
    'orderName': '6422',
    'modelCode': '6422',
    'modelDescription': 'Vestido teste',
    'desiredQuantityText': '450',
    'fabricText': '900',
    'overlapText': '4',
    'notes': 'Observação de teste',
    'sizes': <Object?>[
      <String, Object?>{
        'id': 'tamanho-1',
        'name': 'M',
        'percentageText': '100',
        'blockId': 'bloco-1',
      },
    ],
    'blocks': <Object?>[
      <String, Object?>{
        'id': 'bloco-1',
        'name': 'M',
        'lengthText': '5,20',
      },
    ],
    'fabricColors': <Object?>[
      <String, Object?>{
        'id': 'cor-1',
        'colorName': 'Preto',
        'metersText': '900',
      },
    ],
    'result': null,
    'createdAt': '2026-07-24T12:00:00.000',
    'updatedAt': '2026-07-24T12:00:00.000',
  },
};
