Proyecto: Sistema de Denuncias DUOC (Flutter + Flask) - Versión Segura

Este proyecto Full-Stack implementa una aplicación móvil para registrar denuncias (incluyendo foto y geolocalización) y una API RESTful en Python Flask. La versión actual ha sido reforzada con estándares de seguridad, incluyendo autenticación JWT y protección de datos en el cliente.I.

Fase Backend: API REST con Flask y SQLite (Seguridad JWT)El objetivo fue asegurar las rutas críticas utilizando JSON Web Tokens (JWT) y una clave secreta cargada desde variables de entorno.

  1. Estructura y EndpointsMétodoEndpointDescripciónRequerimiento de TokenPOST/loginAutenticación. Recibe user y password y retorna un JWT Access Token.NoPOST/api/denunciasCrea una denuncia. Recibe multipart/form-      data (incluyendo foto).SÍ (@jwt_required())GET/api/denunciasLista todas las denuncias.NoGET/api/denuncias/<id>Obtiene el detalle de una denuncia específica (ID es un UUID).
  2. No2. Implementaciones de Seguridad en FlaskAutenticación JWT: Se utiliza Flask-JWT-Extended para crear un token de acceso al iniciar sesión.Protección de Rutas: La ruta POST /api/denuncias está protegida por       el decorador @jwt_required(), exigiendo un token válido en el header Authorization: Bearer <token>.Identificadores Seguros: El ID de cada denuncia se genera como un UUID v4 en lugar de un ID autoincrementable      para evitar la enumeración de recursos.
  3. Configuración y Ejecución del BackendRequisitos: Python 3.x, pip install Flask Flask-CORS Flask-JWT-Extended python-dotenv.Configurar Secreto: Crear un archivo .env en la raíz del servidor Flask con la             clave secreta:JWT_SECRET_KEY="tu_clave_secreta_unica"
     
Iniciar API: 
Ejecutar el servidor. (Credenciales de prueba: user: admin, password: 123456).Bashpython app.py
Exponer con Ngrok: Obtener una URL HTTPS para la comunicación con Flutter (ej., https://ejemplo.ngrok-free.dev). Actualizar lib/config/app_config.dart.II. 

Fase Frontend: Aplicación Flutter (Seguridad en el Cliente)El frontend se actualizó para manejar el ciclo de vida de la sesión de manera segura y proteger la privacidad visual.

  1. Librerías de Seguridad Implementadasflutter_secure_storage: Utilizada para guardar el token JWT en el keychain (iOS) o almacén cifrado (Android) en lugar de usar SharedPreferences (almacenamiento en texto       plano).flutter_windowmanager: Utilizada para aplicar la flag de seguridad de Android (FLAG_SECURE) y prevenir capturas de pantalla y grabaciones de pantalla (DLP) mientras la aplicación está en primer plano.
  2. Estructura y Lógica de SesiónLoginScreen (Nuevo): Pantalla dedicada para solicitar credenciales, obtener el token JWT y guardarlo usando flutter_secure_storage.ApiService (Modificado):Implementa loginUser(),       getToken(), y deleteToken().Configura un Interceptor Dio que automáticamente lee el token guardado e inyecta el header Authorization: Bearer <token> en cada solicitud protegida (como crearDenuncia).main.dart       (Modificado):Llama a secureScreen() al inicio para aplicar el bloqueo de capturas.Utiliza FutureBuilder para revisar getToken() y redirigir al usuario a ListComplaintsScreen si ya existe una sesión válida          (Persistencia de Sesión).ListComplaintsScreen (Modificado): Incluye un botón Cerrar Sesión que llama a deleteToken() y redirige a LoginScreen.

PRUEBA DE UN POST SIN TOKEN:
<img width="1920" height="1080" alt="Intento de post sin token" src="https://github.com/user-attachments/assets/eaa00fa4-7f25-4ca1-9c98-5e0784e7683c" />

POST DEL LOGIN PARA GENERAR EL TOKEN:
<img width="1920" height="1080" alt="Post del login" src="https://github.com/user-attachments/assets/5ec3d132-434d-4f5e-8da9-1dcf577a33ed" />

PRUEBA DE UN POST CON EL TOKEN INGRESADO:
<img width="1920" height="1080" alt="Post con el token generado" src="https://github.com/user-attachments/assets/0b3257a5-b3e0-46c1-883b-b828837dc015" />

GET CON LA DENUNCIA AGREGADA:
<img width="1920" height="1080" alt="Get con la denuncia creada" src="https://github.com/user-attachments/assets/5eabb7b5-1373-4033-8db7-b687f04bd825" />





