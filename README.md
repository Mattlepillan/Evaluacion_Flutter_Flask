Desarrollo del Proyecto: App Flutter + API Flask

I. Fase Backend: API REST con Flask y SQLite
El objetivo inicial fue crear la API REST que manejaría las denuncias, la subida de imágenes y la persistencia en SQLite.


1. Estructura y Endpoints (server-flask)
Configuración: Se definió la base de datos (database.db), la carpeta de subidas (uploads/), y se inicializó Flask con CORS.

Endpoints Implementados:


POST /api/denuncias: Crea una denuncia, recibe multipart/form-data, guarda la foto en uploads/, y persiste los datos en SQLite.


GET /api/denuncias: Lista todas las denuncias.


GET /api/denuncias/<id>: Obtiene el detalle de una denuncia específica.

Seguridad y URL: Se utilizó secure_filename para el manejo seguro de archivos y se implementó una función row_to_dict para formatear los resultados de SQLite como JSON.


2. Despliegue y Pruebas con Ngrok

Ejecución: Flask se levantó en http://localhost:5000.



Exposición: Se utilizó Ngrok para exponer la API y obtener una URL pública (HTTPS), la cual se usó como baseUrl configurable en la aplicación Flutter.


Pruebas: Se utilizó Postman para verificar la funcionalidad de POST (con form-data y File para la foto), GET y GET /<id>.

II. Fase Frontend: Aplicación Flutter
El objetivo fue construir la aplicación móvil con tres pantallas, manejo de permisos, y el consumo del API.


1. Estructura del Código (app-flutter)

Organización: Se siguió una estructura modular con carpetas separadas: models/, services/, screens/.


Configuración: Se creó app_config.dart para almacenar la baseUrl de Ngrok de manera configurable.

Modelo de Datos (Denuncia): Se creó el modelo Dart (Denuncia.fromJson) y se robusteció con funciones de parseo para manejar correctamente la conversión de tipos (ej., int a double) en las coordenadas de ubicación.

2. Implementación de Servicios y Lógica
ApiService:

Implementó crearDenuncia: Utiliza la librería dio para enviar datos y la imagen en formato multipart/form-data al endpoint POST.

Implementó listarDenuncias y obtenerDetalle: Utiliza peticiones GET y mapea la respuesta JSON al modelo Denuncia.

nueva_denuncia_screen:

Implementó un formulario con validaciones (correo, descripción).


Implementó la solicitud de permisos y la obtención de la ubicación (geolocator).

Implementó un dialog para seleccionar la fuente de la foto (Cámara o Galería).

3. Implementación de Pantallas

listar_denuncias_screen: Utiliza FutureBuilder para consumir listarDenuncias, muestra miniatura, correo y descripción, e implementa la función RefreshIndicator (pull-to-refresh).


detalle_denuncia_screen: Consume obtenerDetalle(id) y muestra la información completa, incluyendo la foto, ubicación y fecha.



PRUEBAS POSTMAN:

LISTA DE DENUNCIAS:
<img width="1920" height="1080" alt="Lista de denuncias en Postman" src="https://github.com/user-attachments/assets/1c409a22-1d34-4b43-b1ef-dfa8f38a6342" />

AGREGANDO UNA DENUNCIA:
<img width="1920" height="1080" alt="Nueva denuncia agregada desde postman" src="https://github.com/user-attachments/assets/3ed381f3-ee6e-47cb-bdf7-f7ef2b09a6c6" />

PANTALLA DE LA LISTA DE DENUNCIAS:
<img width="1920" height="1080" alt="Pantalla Lista de denuncias" src="https://github.com/user-attachments/assets/b2bf54d7-e0d5-489b-a5f2-e076e6810b61" />

PANTALLA DE DETALLE DE LA DENUNCIA:
<img width="1920" height="1080" alt="Pantalla Detalle de denuncias" src="https://github.com/user-attachments/assets/0c033f3d-973d-4a3d-b7cf-04aefdd6621a" />

PANTALLA DE AGREGAR DENUNCIAS:
<img width="1920" height="1080" alt="Pantalla Nueva denuncia" src="https://github.com/user-attachments/assets/c1f5f0d6-09e1-4c37-ae76-a80e9269eb1d" />











