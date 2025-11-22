// lib/main.dart

import 'package:flutter/material.dart';
import 'package:app_comunidad_estudiantil/screens/listar_denuncias_screen.dart';

void main() {
  // Asegúrate de que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicia la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denuncias DUOC',
      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[800], // Color institucional
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      // La pantalla de Listado de Denuncias es la principal
      home: const ListComplaintsScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}