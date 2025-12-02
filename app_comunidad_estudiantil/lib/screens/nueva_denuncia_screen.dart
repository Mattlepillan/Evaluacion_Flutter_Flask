// lib/screens/nueva_denuncia_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart'; // Tu servicio de API

class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _descripcionController = TextEditingController();

  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final ApiService _apiService = ApiService();

  // --- 1. Seleccionar Fuente de Imagen ---
  void _selectImageSource() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. Obtener la Foto (Método Unificado) ---
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 3. Obtener la Ubicación
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Permiso de ubicación denegado.')));
        }
        setState(() { _isLoading = false; });
        return; 
      }
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📍 Ubicación obtenida.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al obtener ubicación: ${e.toString()}')));
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 4. Enviar Denuncia
  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate() && _imageFile != null && _currentPosition != null) {
      setState(() { _isLoading = true; });

      try {
        await _apiService.crearDenuncia(
          correo: _correoController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          foto: _imageFile!,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Denuncia enviada con éxito!')));
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error al enviar: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    } else {
      String message = 'Por favor, completa el formulario y adjunta todos los datos.';
      if (_imageFile == null) {
        message = 'Falta adjuntar la Foto.';
      } else if (_currentPosition == null) {
         message = 'Falta obtener la Ubicación.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)));
      }
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Denuncia'),
        backgroundColor: Colors.red[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- CAMPOS DE TEXTO ---
              TextFormField(
                controller: _correoController, 
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo DUOC', hintText: 'ejemplo@duoc.cl', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (value) {
                  if (value == null || value.isEmpty || !_emailRegex.hasMatch(value)) {
                    return 'Ingrese un formato de correo válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descripcionController, 
                decoration: const InputDecoration(labelText: 'Descripción del Problema', hintText: 'Detalle el problema...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres.';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 25),
              const Divider(),

              // --- BOTÓN FOTO (Ahora llama al selector) ---
              ElevatedButton.icon(
                onPressed: _selectImageSource, 
                icon: const Icon(Icons.camera_alt),
                label: Text(_imageFile == null ? '1. Adjuntar Foto (Obligatorio)' : 'Foto Seleccionada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _imageFile != null ? Colors.green : Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 10),
              if (_imageFile != null)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              // --- BOTÓN UBICACIÓN ---
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: const Icon(Icons.location_on),
                label: _isLoading 
                    ? const Text('Obteniendo ubicación...')
                    : Text(_currentPosition == null ? '2. Obtener Ubicación (Obligatorio)' : 'Ubicación Obtenida: (${_currentPosition!.latitude.toStringAsFixed(3)}, ${_currentPosition!.longitude.toStringAsFixed(3)})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPosition != null ? Colors.green : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTÓN ENVIAR ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('ENVIAR DENUNCIA'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}