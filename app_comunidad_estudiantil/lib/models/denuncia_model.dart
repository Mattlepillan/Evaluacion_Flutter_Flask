// lib/models/denuncia_model.dart

class Denuncia {
  // MODIFICACIÓN CRÍTICA: ID ahora es String para soportar UUID
  final String id; 
  final String correo;
  final String descripcion;
  final String fotoUrl;
  final Map<String, double> ubicacion; 
  final String fecha; 

  Denuncia({
    required this.id, // String
    required this.correo,
    required this.descripcion,
    required this.fotoUrl,
    required this.ubicacion,
    required this.fecha,
  });

  factory Denuncia.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para asegurar que el valor sea double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      // Intenta parsear si es string
      if (value is String) return double.tryParse(value) ?? 0.0; 
      return 0.0;
    }
    
    final Map<String, dynamic> ubicacionJson = json['ubicacion'] ?? {};

    return Denuncia(
      // MODIFICACIÓN: Se espera que 'id' sea un String (el UUID)
      id: json['id'] as String, 
      correo: json['correo'] as String,
      descripcion: json['descripcion'] as String,
      fotoUrl: json['foto_url'] as String, 
      
      // Asegura que lat y lng sean double
      ubicacion: {
        'lat': parseDouble(ubicacionJson['lat']),
        'lng': parseDouble(ubicacionJson['lng']),
      },
      
      fecha: json['fecha'] as String,
    );
  }
}