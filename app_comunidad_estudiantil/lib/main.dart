// lib/main.dart

import 'package:app_comunidad_estudiantil_v1/screens/listar_denuncias_screen.dart';
import 'package:app_comunidad_estudiantil_v1/screens/login_screen.dart';
import 'package:app_comunidad_estudiantil_v1/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Para defaultTargetPlatform
// Librería para el bloqueo de capturas (Requisito de seguridad)
import 'package:flutter_windowmanager/flutter_windowmanager.dart'; 

// Importaciones de screens y servicios



void main() {
  // Asegúrate de que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicia la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Requerimiento de seguridad: Bloquear capturas de pantalla (Android)
  Future<void> secureScreen() async {
    // Solo aplica en Android para evitar errores de plataforma en otros SO
    if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE); 
          print('Bloqueo de capturas activado.');
        } on PlatformException catch (e) {
          print("Error al activar FLAG_SECURE: ${e.message}");
        }
    }
  }

  // Lógica para decidir la pantalla inicial (Persistencia de Sesión)
  Future<Widget> _getInitialScreen() async {
    await secureScreen(); 
    
    // Verifica si existe un token guardado de forma segura
    final token = await ApiService().getToken(); 
    
    // Si hay token, va al listado; si no, va al login.
    return token != null ? const ListComplaintsScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denuncias DUOC Segura',
      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[800], 
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      
      // Usa FutureBuilder para esperar la verificación del token
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(), // El Future que revisa el token
        
        // El 'builder' que faltaba
        builder: (context, snapshot) { 
          // Si el future ya terminó (revisó el token)
          if (snapshot.connectionState == ConnectionState.done) {
            // Retorna la pantalla decidida (ListComplaintsScreen o LoginScreen)
            // Si snapshot.data es nulo, por seguridad, va a LoginScreen
            return snapshot.data ?? const LoginScreen(); 
          }
          // Mientras se carga y verifica el token, muestra un indicador de progreso
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); 
        },
      ), 
      debugShowCheckedModeBanner: false,
    );
  }
}