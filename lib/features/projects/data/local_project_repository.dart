import 'dart:convert';
import 'dart:io';

import 'package:grade_opera/core/constants/app_constants.dart';
import 'package:grade_opera/core/utils/id_generator.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/projects/domain/repositories/project_repository.dart';
import 'package:path_provider/path_provider.dart';

class LocalProjectRepository implements ProjectRepository {
  LocalProjectRepository._(this._storageFile);

  final File _storageFile;

  static Future<LocalProjectRepository> create() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final dataDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}GRADE OPERA',
    );
    await dataDirectory.create(recursive: true);
    return LocalProjectRepository._(
      File('${dataDirectory.path}${Platform.pathSeparator}projects.json'),
    );
  }

  @override
  Future<void> addHistory(ProjectDocument entry) async {
    final database = await _readDatabase();
    final history = database.history.toList()
      ..insert(
        0,
        entry.copyWith(
          id: IdGenerator.create('historico'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    if (history.length > AppConstants.maximumHistoryEntries) {
      history.removeRange(AppConstants.maximumHistoryEntries, history.length);
    }
    await _writeDatabase(database.copyWith(history: history));
  }

  @override
  Future<void> deleteProject(String id) async {
    final database = await _readDatabase();
    await _writeDatabase(
      database.copyWith(
        projects: database.projects
            .where((project) => project.id != id)
            .toList(),
      ),
    );
  }

  @override
  Future<ProjectDocument> duplicateProject(String id) async {
    final database = await _readDatabase();
    final source = database.projects.firstWhere((project) => project.id == id);
    final now = DateTime.now();
    final duplicate = source.copyWith(
      id: IdGenerator.create('projeto'),
      orderName: '${source.orderName} — cópia',
      createdAt: now,
      updatedAt: now,
    );
    await _writeDatabase(
      database.copyWith(
        projects: <ProjectDocument>[duplicate, ...database.projects],
      ),
    );
    return duplicate;
  }

  @override
  Future<List<ProjectDocument>> listHistory() async =>
      List<ProjectDocument>.unmodifiable((await _readDatabase()).history);

  @override
  Future<List<ProjectDocument>> listProjects() async =>
      List<ProjectDocument>.unmodifiable((await _readDatabase()).projects);

  @override
  Future<void> saveProject(ProjectDocument project) async {
    final database = await _readDatabase();
    final projects = database.projects.toList();
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index < 0) {
      projects.insert(0, project);
    } else {
      projects[index] = project;
    }
    await _writeDatabase(database.copyWith(projects: projects));
  }

  Future<_Database> _readDatabase() async {
    if (!await _storageFile.exists()) {
      return const _Database(
        projects: <ProjectDocument>[],
        history: <ProjectDocument>[],
      );
    }
    try {
      final content = await _storageFile.readAsString();
      final json = jsonDecode(content) as Map<String, Object?>;
      return _Database.fromJson(json);
    } on Object {
      final backup = File(
        '${_storageFile.path}.corrompido_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _storageFile.rename(backup.path);
      return const _Database(
        projects: <ProjectDocument>[],
        history: <ProjectDocument>[],
      );
    }
  }

  Future<void> _writeDatabase(_Database database) async {
    final temporary = File('${_storageFile.path}.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await temporary.writeAsString(
      encoder.convert(database.toJson()),
      flush: true,
    );
    if (await _storageFile.exists()) {
      await _storageFile.delete();
    }
    await temporary.rename(_storageFile.path);
  }
}

class _Database {
  const _Database({required this.projects, required this.history});

  final List<ProjectDocument> projects;
  final List<ProjectDocument> history;

  _Database copyWith({
    List<ProjectDocument>? projects,
    List<ProjectDocument>? history,
  }) => _Database(
    projects: projects ?? this.projects,
    history: history ?? this.history,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 2,
    'projects': projects.map((item) => item.toJson()).toList(),
    'history': history.map((item) => item.toJson()).toList(),
  };

  factory _Database.fromJson(Map<String, Object?> json) => _Database(
    projects: (json['projects'] as List<Object?>? ?? <Object?>[])
        .map((item) => ProjectDocument.fromJson(item! as Map<String, Object?>))
        .toList(),
    history: (json['history'] as List<Object?>? ?? <Object?>[])
        .map((item) => ProjectDocument.fromJson(item! as Map<String, Object?>))
        .toList(),
  );
}
