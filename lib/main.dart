import 'package:flutter/material.dart';
import 'screens/workspace_screen.dart';

void main() {
  runApp(const CableSimApp());
}

class CableSimApp extends StatelessWidget {
  const CableSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CableSim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C3E50)),
        useMaterial3: true,
      ),
      home: const WorkspaceScreen(),
    );
  }
}
