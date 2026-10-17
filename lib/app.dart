import 'package:flutter/material.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/clinova_theme.dart';

class ClinovaApp extends StatelessWidget {
  const ClinovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinova',
      debugShowCheckedModeBanner: false,
      theme: ClinovaTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
