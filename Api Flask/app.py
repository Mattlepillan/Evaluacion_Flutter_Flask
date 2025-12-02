# pip install Flask flask-cors
# pip install Flask Flask-CORS Flask-JWT-Extended python-dotenv
# ngrok config add-authtoken 35TsNqpYLQOYFMqoTk2ZuI26Vx2_7P6HoAG3CdWWkkb558qVp
# ./ngrok http 5000


import os
import sqlite3
import datetime
import uuid 
from flask import Flask, request, jsonify, send_from_directory, url_for
from werkzeug.utils import secure_filename
from flask_cors import CORS
from flask_jwt_extended import create_access_token, jwt_required, JWTManager
from dotenv import load_dotenv

# Cargar variables de entorno al inicio (necesario para JWT_SECRET_KEY)
load_dotenv() 

# --- CONFIGURACIÓN DE LA APLICACIÓN ---
UPLOAD_FOLDER = 'uploads'
DATABASE = 'database.db'

app = Flask(__name__)
CORS(app) 
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
    print(f"Carpeta '{UPLOAD_FOLDER}' creada.")

# -------------------------------------------------------------------
# CONFIGURACIÓN DE JWT
# -------------------------------------------------------------------
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "fallback-secret-key-development-only") 
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = datetime.timedelta(hours=1)
jwt = JWTManager(app)

# --- MANEJO DE BASE DE DATOS (SQLite) ---

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row 
    return conn

def init_db():
    conn = get_db_connection()
    # Tabla con ID de tipo TEXT (UUID)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS denuncias (
            id TEXT PRIMARY KEY, 
            correo TEXT NOT NULL,
            descripcion TEXT NOT NULL,
            ubicacion_lat REAL NOT NULL,
            ubicacion_lng REAL NOT NULL,
            foto_path TEXT NOT NULL,
            fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ''')
    conn.commit()
    conn.close()
    print("Base de datos inicializada (tabla 'denuncias' con UUID listo).")

with app.app_context():
    init_db()

def row_to_dict(row):
    """Convierte una fila de sqlite3.Row a un diccionario y genera la URL de la foto."""
    data = dict(row)
    data['foto_url'] = url_for('uploaded_file', filename=data['foto_path'], _external=True, _scheme='https')
    
    data['ubicacion'] = {
        'lat': data.pop('ubicacion_lat'),
        'lng': data.pop('ubicacion_lng'),
    }
    data.pop('foto_path', None)
    return data

# --- ENDPOINTS PÚBLICOS ---

# Endpoint para servir archivos subidos (fotos)
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# 1. GET /api/denuncias -> Lista de denuncias (PÚBLICA)
@app.route('/api/denuncias', methods=['GET'])
def listar_denuncias():
    conn = get_db_connection()
    denuncias = conn.execute('SELECT * FROM denuncias ORDER BY fecha DESC').fetchall()
    conn.close()

    denuncias_list = [row_to_dict(denuncia) for denuncia in denuncias]

    return jsonify(denuncias_list), 200

# 2. GET /api/denuncias/<id> -> Detalle por id (PÚBLICA)
@app.route('/api/denuncias/<id>', methods=['GET'])
def detalle_denuncia(id):
    conn = get_db_connection()
    denuncia = conn.execute('SELECT * FROM denuncias WHERE id = ?', (id,)).fetchone()
    conn.close()

    if denuncia is None:
        return jsonify({'error': f'Denuncia con ID {id} no encontrada.'}), 404

    return jsonify(row_to_dict(denuncia)), 200

# --- ENDPOINT DE AUTENTICACIÓN ---

@app.route('/login', methods=['POST'])
def login():
    """
    Endpoint para autenticación. Recibe 'user' y 'password'. Retorna un JWT access token.
    """
    data = request.get_json()
    # MODIFICACIÓN CLAVE: Se extrae 'user' en lugar de 'correo'
    user = data.get('user', None) 
    password = data.get('password', None)
    
    # Validación simple (MOCK)
    # MODIFICACIÓN CLAVE: Se valida 'user'
    if user == 'admin' and password == '123456': 
        # El token se crea con el nombre de usuario como identidad
        access_token = create_access_token(identity=user) 
        return jsonify(access_token=access_token), 200
    
    return jsonify({"msg": "Usuario o contraseña inválidos."}), 401

# --- ENDPOINT PROTEGIDO ---

# 3. POST /api/denuncias -> Crea denuncia (REQUIERE TOKEN)
@app.route('/api/denuncias', methods=['POST'])
@jwt_required() 
def crear_denuncia():
    """
    Crea una nueva denuncia. Requiere un token JWT.
    """
    if 'foto' not in request.files:
        return jsonify({'error': 'Falta el campo de la foto.'}), 400
    
    foto = request.files['foto']
    
    correo = request.form.get('correo')
    descripcion = request.form.get('descripcion')
    ubicacion_lat = request.form.get('ubicacion_lat')
    ubicacion_lng = request.form.get('ubicacion_lng')
    
    if not correo or not descripcion or not ubicacion_lat or not ubicacion_lng:
        return jsonify({'error': 'Faltan campos obligatorios.'}), 400

    # Generar UUID
    denuncia_uuid = str(uuid.uuid4())
    
    # Guardar la foto de forma segura
    ext = os.path.splitext(foto.filename)[1] if foto.filename else '.jpg'
    timestamp_name = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    random_hex = os.urandom(4).hex()
    filename = secure_filename(f"{timestamp_name}_{random_hex}{ext}")
    
    foto_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    foto.save(foto_path)

    # Persistir en SQLite
    try:
        conn = get_db_connection()
        conn.execute(
            'INSERT INTO denuncias (id, correo, descripcion, ubicacion_lat, ubicacion_lng, foto_path) VALUES (?, ?, ?, ?, ?, ?)',
            (denuncia_uuid, correo, descripcion, float(ubicacion_lat), float(ubicacion_lng), filename)
        )
        conn.commit()
        conn.close()

        foto_url = url_for('uploaded_file', filename=filename, _external=True, _scheme='https')

        return jsonify({
            'message': 'Denuncia creada con éxito.',
            'id': denuncia_uuid, 
            'foto_url': foto_url
        }), 201

    except ValueError:
        return jsonify({'error': 'La ubicación (lat/lng) debe ser un valor numérico.'}), 400
    except Exception as e:
        return jsonify({'error': f'Error interno del servidor: {str(e)}'}), 500


# --- INICIALIZACIÓN ---

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)