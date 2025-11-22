// lib/screens/list_complaints_screen.dart

import 'package:flutter/material.dart';
import '../models/denuncia_model.dart';
import '../services/api_service.dart';
import 'detalle_denuncia_screen.dart'; // Necesitas esta pantalla para la navegación
import 'nueva_denuncia_screen.dart'; // Para navegar a crear denuncia

class ListComplaintsScreen extends StatefulWidget {
  const ListComplaintsScreen({super.key});

  @override
  State<ListComplaintsScreen> createState() => _ListComplaintsScreenState();
}

class _ListComplaintsScreenState extends State<ListComplaintsScreen> {
  // Inicializamos la llamada a la API en un Future
  late Future<List<Denuncia>> _denunciasFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _denunciasFuture = _apiService.listarDenuncias();
  }

  // Método para recargar la lista (usado por pull-to-refresh)
  Future<void> _refreshDenuncias() async {
    setState(() {
      _denunciasFuture = _apiService.listarDenuncias();
    });
  }

  // Navegar al detalle
  void _navigateToDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailComplaintScreen(denunciaId: id),
      ),
    ).then((_) {
      // Recargar la lista si se regresa, en caso de que se haya creado una nueva denuncia
      _refreshDenuncias();
    });
  }
  
  // Navegar a crear denuncia
  void _navigateToNewComplaint() async {
    // Esperamos el resultado de la pantalla de creación (true si se creó con éxito)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewComplaintScreen()),
    );
    
    // Si la denuncia fue creada, recargamos la lista
    if (result == true) {
      _refreshDenuncias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denuncias DUOC'),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Denuncia',
            onPressed: _navigateToNewComplaint,
          ),
        ],
      ),
      // Implementa el pull-to-refresh
      body: RefreshIndicator( 
        onRefresh: _refreshDenuncias,
        child: FutureBuilder<List<Denuncia>>(
          future: _denunciasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error de conexión: ${snapshot.error}. Asegúrate de que Ngrok esté corriendo.'),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: ListView( // Usamos ListView para que el RefreshIndicator funcione
                  children: const [
                    SizedBox(height: 100),
                    Icon(Icons.inbox, size: 50, color: Colors.grey),
                    Text('No hay denuncias registradas.', textAlign: TextAlign.center),
                  ],
                ),
              );
            } else {
              // Muestra el listado de denuncias
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final denuncia = snapshot.data![index];
                  return DenunciaListItem(
                    denuncia: denuncia,
                    onTap: () => _navigateToDetail(denuncia.id),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

// Widget auxiliar para cada elemento de la lista
class DenunciaListItem extends StatelessWidget {
  final Denuncia denuncia;
  final VoidCallback onTap;

  const DenunciaListItem({
    required this.denuncia,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        // Muestra la miniatura de la foto
        leading: Container( 
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(denuncia.fotoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Muestra el correo y la descripción
        title: Text(
          denuncia.correo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          denuncia.descripcion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}