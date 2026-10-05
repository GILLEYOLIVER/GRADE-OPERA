import 'dart:convert';
import 'dart:io';

import 'package:grade_opera/features/projects/domain/entities/project_document.dart';

class ProjectFileImportException implements Exception {
  const ProjectFileImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ProjectFileImporter {
  Future<ProjectDocument> importProject(String filePath);
}

class LocalProjectFileImporter implements ProjectFileImporter {
  const LocalProjectFileImporter();

  @override
  Future<ProjectDocument> importProject(String filePath) async {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty ||
        !normalizedPath.toLowerCase().endsWith('.gradeopera.json')) {
      throw const ProjectFileImportException(
        'O arquivo selecionado não é um projeto do GRADE OPERA.',
      );
    }

    final file = File(normalizedPath);
    try {
      if (!await file.exists()) {
        throw const ProjectFileImportException(
          'O arquivo selecionado não foi encontrado.',
        );
      }

      final decoded = jsonDecode(await file.readAsString(encoding: utf8));
      if (decoded is! Map) {
        throw const ProjectFileImportException(
          'O arquivo está corrompido ou possui um formato inválido.',
        );
      }

      final root = Map<String, Object?>.from(decoded);
      final schemaVersion = root['schemaVersion'];
      if (schemaVersion is! int || schemaVersion != 1) {
        throw const ProjectFileImportException(
          'Esta versão do arquivo não é compatível com o aplicativo.',
        );
      }

      if (root['application'] != 'GRADE OPERA') {
        throw const ProjectFileImportException(
          'O arquivo selecionado não é um projeto do GRADE OPERA.',
        );
      }

      final projectJson = root['project'];
      if (projectJson is! Map) {
        throw const ProjectFileImportException(
          'O arquivo selecionado não é um projeto do GRADE OPERA.',
        );
      }

      return ProjectDocument.fromJson(Map<String, Object?>.from(projectJson));
    } on ProjectFileImportException {
      rethrow;
    } on FileSystemException {
      throw const ProjectFileImportException(
        'Não foi possível acessar o arquivo selecionado.',
      );
    } on IOException {
      throw const ProjectFileImportException(
        'Não foi possível acessar o arquivo selecionado.',
      );
    } on FormatException {
      throw const ProjectFileImportException(
        'O arquivo está corrompido ou possui um formato inválido.',
      );
    } on TypeError {
      throw const ProjectFileImportException(
        'O arquivo está corrompido ou possui um formato inválido.',
      );
    } on Object {
      throw const ProjectFileImportException(
        'O arquivo está corrompido ou possui um formato inválido.',
      );
    }
  }
}
