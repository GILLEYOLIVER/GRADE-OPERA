import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grade_opera/app/grade_opera_app.dart';
import 'package:grade_opera/features/projects/data/local_project_repository.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    await windowManager.setMinimumSize(const Size(760, 600));
    await windowManager.setTitle('GRADE OPERA');
  }
  final repository = await LocalProjectRepository.create();
  runApp(GradeOperaApp(repository: repository));
}
