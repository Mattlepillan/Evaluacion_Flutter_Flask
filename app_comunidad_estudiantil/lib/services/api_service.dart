// lib/services/api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import '../config/app_config.dart';
import '../models/denuncia_model.dart'; 

class ApiService {
  // Inicializar storage seguro
  final _storage = const FlutterSecureStorage();
  final Dio _dio;
  
  // Constructor para configurar Dio y el Interceptor
  ApiService() : _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Obtener token antes de cada solicitud 
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            // Inyectar el token en el header Authorization: Bearer <token>
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // Manejo de errores 401/403 (opcional, pero útil)
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Aquí podrías implementar un logout forzado si el token expira
            print("Token expirado o inválido. Redirigiendo a login.");
          }
          return handler.next(error);
        },
      ),
    );
  }

  // --- 0. Gestión de Sesión ---
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- 1. POST /login (Login de Usuario) ---
  // MODIFICADO: Usa 'user' para la autenticación
  Future<void> loginUser({required String user, required String password}) async {
    try {
      final response = await _dio.post(
        '/login', 
        data: {'user': user, 'password': password}, // Envía 'user'
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        if (token != null) {
          await saveToken(token); // Guardar token de forma segura
        }
      } else {
        throw Exception('Fallo de autenticación: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
         throw Exception('Credenciales inválidas.');
      }
      throw Exception('Error de conexión o API: ${e.message}');
    }
  }

  // --- 2. POST /api/denuncias (Crear Denuncia) ---
  // RUTA PROTEGIDA - El token se inyecta por el interceptor
  Future<void> crearDenuncia({
    required String correo,
    required String descripcion,
    required double lat,
    required double lng,
    required File foto,
  }) async {
    String fileName = foto.path.split('/').last;
    
    MultipartFile fotoMultipart = await MultipartFile.fromFile(
      foto.path,
      filename: fileName,
    );

    FormData formData = FormData.fromMap({
      'correo': correo,
      'descripcion': descripcion,
      'ubicacion_lat': lat.toString(),
      'ubicacion_lng': lng.toString(),
      'foto': fotoMultipart, 
    });

    try {
      final response = await _dio.post('/api/denuncias', data: formData);

      if (response.statusCode != 201) {
        final errorMsg = response.data['error'] ?? 'Error desconocido';
        throw Exception('Error al crear denuncia (${response.statusCode}): $errorMsg');
      }
    } on DioException catch (e) {
      final errorDetail = e.response?.data['error'] ?? e.message;
      throw Exception('Fallo de conexión o API: $errorDetail');
    }
  }

  // --- 3. GET /api/denuncias (Listar Denuncias) ---
  Future<List<Denuncia>> listarDenuncias() async {
    try {
      final response = await _dio.get('/api/denuncias');

      if (response.statusCode == 200) {
        if (response.data is List) {
           List<dynamic> denunciasJson = response.data; 
           return denunciasJson.map((json) => Denuncia.fromJson(json)).toList();
        } else {
           throw Exception('Respuesta inesperada de la API: Se esperaba una lista.');
        }
      } else {
        throw Exception('Error al obtener listado de denuncias: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Fallo de conexión al listar denuncias: ${e.message}');
    }
  }

  // --- 4. GET /api/denuncias/<id> (Detalle de Denuncia) ---
  // MODIFICADO: El ID ahora es de tipo String (UUID)
  Future<Denuncia> obtenerDetalle(String id) async {
    try {
      final response = await _dio.get('/api/denuncias/$id');

      if (response.statusCode == 200) {
        return Denuncia.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Denuncia con ID $id no encontrada.');
      } 
      else {
        throw Exception('Error al obtener detalle de denuncia: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Fallo de conexión al obtener detalle: ${e.message}');
    }
  }
}