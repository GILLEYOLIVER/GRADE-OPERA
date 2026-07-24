import 'dart:convert';
import 'dart:io';

import 'package:grade_opera/features/projects/domain/entities/project_document.dart';

abstract interface class ProjectFileExporter {
  Future<String> exportProject(
    ProjectDocument project, {
    required String directoryPath,
  });
}

class LocalProjectFileExporter implements ProjectFileExporter {
  const LocalProjectFileExporter();

  @override
  Future<String> exportProject(
    ProjectDocument project, {
    required String directoryPath,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw FileSystemException(
        'A pasta selecionada não está disponível.',
        directoryPath,
      );
    }

    final baseName = _safeFileName(
      project.modelCode.trim().isNotEmpty
          ? project.modelCode
          : project.modelDescription,
    );
    final prefix = 'GRADE_OPERA_${baseName.isEmpty ? 'projeto' : baseName}';
    var destination = File(
      '${directory.path}${Platform.pathSeparator}$prefix.gradeopera.json',
    );
    var suffix = 2;
    while (await destination.exists()) {
      destination = File(
        '${directory.path}${Platform.pathSeparator}'
        '$prefix ($suffix).gradeopera.json',
      );
      suffix++;
    }

    const encoder = JsonEncoder.withIndent('  ');
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsString(
      encoder.convert(<String, Object?>{
        'schemaVersion': 1,
        'application': 'GRADE OPERA',
        'project': project.toJson(),
      }),
      flush: true,
    );
    await temporary.rename(destination.path);
    return destination.path;
  }

  String _safeFileName(String value) => value
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[. ]+$'), '');
}
