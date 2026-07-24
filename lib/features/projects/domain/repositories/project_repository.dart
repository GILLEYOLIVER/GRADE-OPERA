import 'package:grade_opera/features/projects/domain/entities/project_document.dart';

abstract interface class ProjectRepository {
  Future<List<ProjectDocument>> listProjects();
  Future<void> saveProject(ProjectDocument project);
  Future<void> deleteProject(String id);
  Future<ProjectDocument> duplicateProject(String id);
  Future<List<ProjectDocument>> listHistory();
  Future<void> addHistory(ProjectDocument entry);
}
