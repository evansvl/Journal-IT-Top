import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- ДОБАВИТЬ ЭТОТ ИМПОРТ
import 'package:flutter_localizations/flutter_localizations.dart';
import 'login.dart';

void main() async {
  // <--- СДЕЛАТЬ main АСИНХРОННОЙ
  // Убедимся, что Flutter Engine инициализирован перед установкой ориентации
  WidgetsFlutterBinding.ensureInitialized(); // <--- ОБЯЗАТЕЛЬНО ДОБАВИТЬ

  // Устанавливаем предпочтительные ориентации
  await SystemChrome.setPreferredOrientations([
    // <--- await, т.к. это Future
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const StartApp());
}

class StartApp extends StatelessWidget {
  const StartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Электронный дневник',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1.0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: const LoginPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', ''),
        Locale('en', ''),
      ],
      locale: const Locale('ru', 'RU'),
    );
  }
}
