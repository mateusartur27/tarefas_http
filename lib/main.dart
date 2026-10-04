import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() => runApp(const TarefasApp());

class TarefasApp extends StatelessWidget {
  const TarefasApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Minhas Tarefas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3355d9)),
      scaffoldBackgroundColor: const Color(0xfff5f6fb),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}
