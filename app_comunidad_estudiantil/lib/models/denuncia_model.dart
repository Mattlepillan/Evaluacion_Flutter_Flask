// lib/models/denuncia_model.dart

class Denuncia {
  final int id;
  final String correo;
  final String descripcion;
  final String fotoUrl;
  final Map<String, double> ubicacion; 
  final String fecha; 

  Denuncia({
    required this.id,
    required this.correo,
    required this.descripcion,
    required this.fotoUrl,
    required this.ubicacion,
    required this.fecha,
  });

  factory Denuncia.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para asegurar que el valor sea double, incluso si viene como int
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      // Intenta parsear si es string
      if (value is String) return double.tryParse(value) ?? 0.0; 
      return 0.0;
    }
    
    // El mapa 'ubicacion' anidado viene de la API Flask
    final Map<String, dynamic> ubicacionJson = json['ubicacion'] ?? {};

    return Denuncia(
      // Se asume que 'id' es un entero (o se convierte)
      id: json['id'] as int,
      correo: json['correo'] as String,
      descripcion: json['descripcion'] as String,
      fotoUrl: json['foto_url'] as String, 
      
      // CRÍTICO: Asegura que lat y lng sean double
      ubicacion: {
        'lat': parseDouble(ubicacionJson['lat']),
        'lng': parseDouble(ubicacionJson['lng']),
      },
      
      fecha: json['fecha'] as String,
    );
  }
}