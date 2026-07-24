import 'package:grade_opera/core/utils/id_generator.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:grade_opera/features/projects/domain/repositories/project_repository.dart';

class InMemoryProjectRepository implements ProjectRepository {
  final List<ProjectDocument> projects = <ProjectDocument>[];
  final List<ProjectDocument> history = <ProjectDocument>[];

  @override
  Future<void> addHistory(ProjectDocument entry) async {
    history.insert(0, entry);
  }

  @override
  Future<void> deleteProject(String id) async {
    projects.removeWhere((project) => project.id == id);
  }

  @override
  Future<ProjectDocument> duplicateProject(String id) async {
    final source = projects.firstWhere((project) => project.id == id);
    final now = DateTime.now();
    final duplicate = source.copyWith(
      id: IdGenerator.create('teste'),
      orderName: '${source.orderName} — cópia',
      createdAt: now,
      updatedAt: now,
    );
    projects.insert(0, duplicate);
    return duplicate;
  }

  @override
  Future<List<ProjectDocument>> listHistory() async =>
      List<ProjectDocument>.unmodifiable(history);

  @override
  Future<List<ProjectDocument>> listProjects() async =>
      List<ProjectDocument>.unmodifiable(projects);

  @override
  Future<void> saveProject(ProjectDocument project) async {
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index < 0) {
      projects.insert(0, project);
    } else {
      projects[index] = project;
    }
  }
}
