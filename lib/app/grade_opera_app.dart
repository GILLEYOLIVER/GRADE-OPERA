import 'package:flutter/material.dart';
import 'package:grade_opera/core/constants/app_constants.dart';
import 'package:grade_opera/core/theme/app_theme.dart';
import 'package:grade_opera/features/cutting_grade/presentation/controllers/grade_controller.dart';
import 'package:grade_opera/features/cutting_grade/presentation/pages/grade_main_page.dart';
import 'package:grade_opera/features/projects/domain/repositories/project_repository.dart';

class GradeOperaApp extends StatefulWidget {
  const GradeOperaApp({required this.repository, super.key});

  final ProjectRepository repository;

  @override
  State<GradeOperaApp> createState() => _GradeOperaAppState();
}

class _GradeOperaAppState extends State<GradeOperaApp> {
  late final GradeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GradeController(repository: widget.repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, child) => MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _controller.themeMode,
      locale: const Locale('pt', 'BR'),
      home: GradeMainPage(controller: _controller),
    ),
  );
}
