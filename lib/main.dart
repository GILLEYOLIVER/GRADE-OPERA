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
    const windowOptions = WindowOptions(
      size: Size(1280, 820),
      minimumSize: Size(760, 600),
      center: true,
      title: 'GRADE OPERA',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }
  final repository = await LocalProjectRepository.create();
  runApp(GradeOperaApp(repository: repository));
}
