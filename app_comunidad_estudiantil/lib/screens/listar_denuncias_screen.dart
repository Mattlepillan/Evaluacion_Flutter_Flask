// lib/screens/listar_denuncias_screen.dart

import 'package:flutter/material.dart';
import '../models/denuncia_model.dart';
import '../services/api_service.dart';
import 'detalle_denuncia_screen.dart'; 
import 'nueva_denuncia_screen.dart'; 
import 'login_screen.dart'; // Importar login

class ListComplaintsScreen extends StatefulWidget {
  const ListComplaintsScreen({super.key});

  @override
  State<ListComplaintsScreen> createState() => _ListComplaintsScreenState();
}

class _ListComplaintsScreenState extends State<ListComplaintsScreen> {
  late Future<List<Denuncia>> _denunciasFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _denunciasFuture = _apiService.listarDenuncias();
  }

  // Método para recargar la lista
  Future<void> _refreshDenuncias() async {
    setState(() {
      _denunciasFuture = _apiService.listarDenuncias();
    });
  }

  // Navegar al detalle (MODIFICADO: id es String)
  void _navigateToDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailComplaintScreen(denunciaId: id),
      ),
    ).then((_) {
      _refreshDenuncias();
    });
  }
  
  // Navegar a crear denuncia
  void _navigateToNewComplaint() async {
    // Esperamos el resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewComplaintScreen()),
    );
    
    // Si la denuncia fue creada, recargamos la lista
    if (result == true) {
      _refreshDenuncias();
    }
  }
  
  // NUEVO MÉTODO: Cierre de Sesión
  void _handleLogout() async {
    await _apiService.deleteToken(); // Borra el token seguro
    
    // Navega a la pantalla de Login y elimina el historial de navegación
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
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
                child: ListView( 
                  children: const [
                    SizedBox(height: 100),
                    Icon(Icons.inbox, size: 50, color: Colors.grey),
                    Text('No hay denuncias registradas.', textAlign: TextAlign.center),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final denuncia = snapshot.data![index];
                  return DenunciaListItem(
                    denuncia: denuncia,
                    onTap: () => _navigateToDetail(denuncia.id), // ID es String
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

// Widget auxiliar para cada elemento de la lista (se mantiene igual)
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