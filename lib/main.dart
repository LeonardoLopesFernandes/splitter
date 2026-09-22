import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const DivisorDeArquivosApp());
}

class DivisorDeArquivosApp extends StatelessWidget {
  const DivisorDeArquivosApp({super.key});

  static const _corTeal = Color(0xFF1FB196);

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.dark(
      primary: _corTeal,
      secondary: _corTeal,
      surface: Color(0xFF171D24),
      error: Color(0xFFEF5350),
    );

    return MaterialApp(
      title: 'Ferramentas de Arquivo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF12181F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131920),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          filled: true,
          fillColor: Color(0xFF232D37),
          hintStyle: TextStyle(color: Color(0xFF6B7C93)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C232C),
          selectedItemColor: _corTeal,
          unselectedItemColor: Color(0xFF6B7C93),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      locale: const Locale('pt', 'BR'),
      home: const HomeScreen(),
    );
  }
}