// lib/services/api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/denuncia_model.dart'; 

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  // --- 1. POST /api/denuncias (Crear Denuncia) ---
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

  // --- 2. GET /api/denuncias (Listar Denuncias) ---
  Future<List<Denuncia>> listarDenuncias() async {
    try {
      final response = await _dio.get('/api/denuncias');

      if (response.statusCode == 200) {
        // CORRECCIÓN: Verificar que la respuesta sea una Lista antes de mapear
        if (response.data is List) {
           List<dynamic> denunciasJson = response.data; 
           return denunciasJson.map((json) => Denuncia.fromJson(json)).toList();
        } else {
           throw Exception('Respuesta inesperada de la API: Se esperaba una lista, se recibió ${response.data.runtimeType}.');
        }
      } else {
        throw Exception('Error al obtener listado de denuncias: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Fallo de conexión al listar denuncias: ${e.message}');
    }
  }

  // --- 3. GET /api/denuncias/<id> (Detalle de Denuncia) ---
  Future<Denuncia> obtenerDetalle(int id) async {
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