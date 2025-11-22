// lib/screens/detail_complaint_screen.dart

import 'package:flutter/material.dart';
import '../models/denuncia_model.dart';
import '../services/api_service.dart';

class DetailComplaintScreen extends StatelessWidget {
  final int denunciaId;
  final ApiService _apiService = ApiService(); 

  DetailComplaintScreen({required this.denunciaId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Denuncia'),
        backgroundColor: Colors.red[800],
      ),
      body: FutureBuilder<Denuncia>(
        future: _apiService.obtenerDetalle(denunciaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error al cargar detalle: ${snapshot.error.toString()}'),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Denuncia no encontrada.'));
          } else {
            final denuncia = snapshot.data!;
            // Si la data es exitosa, construimos la vista de detalle
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FOTO ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      denuncia.fotoUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Center(child: Text('Error al cargar imagen')),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // --- CORREO ---
                  const Text(
                    'Correo del Denunciante',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                  ),
                  Text(
                    denuncia.correo,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Divider(height: 25),

                  // --- DESCRIPCIÓN ---
                  const Text(
                    'Descripción del Problema',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                  ),
                  Text(
                    denuncia.descripcion,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Divider(height: 25),

                  // --- UBICACIÓN ---
                  const Text(
                    'Ubicación (Latitud, Longitud)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${denuncia.ubicacion['lat']!.toStringAsFixed(5)}, Lng: ${denuncia.ubicacion['lng']!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const Divider(height: 25),

                  // --- FECHA ---
                  const Text(
                    'Fecha de Creación',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                  ),
                  Text(
                    denuncia.fecha.substring(0, 16).replaceFirst('T', ' '),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}