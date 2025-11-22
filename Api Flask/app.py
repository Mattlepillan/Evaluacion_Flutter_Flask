# app.py en la carpeta server-flask
# pip install Flask flask-cors
# ngrok config add-authtoken 35TsNqpYLQOYFMqoTk2ZuI26Vx2_7P6HoAG3CdWWkkb558qVp
# ./ngrok http 5000

import os
import sqlite3
import datetime
from flask import Flask, request, jsonify, send_from_directory, url_for
from werkzeug.utils import secure_filename
from flask_cors import CORS

# --- CONFIGURACIÓN ---
UPLOAD_FOLDER = 'uploads'
DATABASE = 'database.db'

app = Flask(__name__)
CORS(app) 
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
    print(f"Carpeta '{UPLOAD_FOLDER}' creada.")

# --- MANEJO DE BASE DE DATOS (SQLite) ---

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    # Permite acceder a las columnas por nombre
    conn.row_factory = sqlite3.Row 
    return conn

def init_db():
    conn = get_db_connection()
    # [cite_start]Una denuncia debe incluir: correo, foto, descripción y ubicación. [cite: 11]
    conn.execute('''
        CREATE TABLE IF NOT EXISTS denuncias (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            correo TEXT NOT NULL,
            descripcion TEXT NOT NULL,
            ubicacion_lat REAL,
            ubicacion_lng REAL,
            foto_path TEXT NOT NULL,
            fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ''')
    conn.commit()
    conn.close()
    print("Base de datos inicializada (tabla 'denuncias' lista).")

with app.app_context():
    init_db()

# --- FUNCIÓN DE UTILIDAD ---
def row_to_dict(row):
    """Convierte una fila de SQLite (Row) a un diccionario y genera la foto_url en HTTPS."""
    denuncia = dict(row)
    
    # -----------------------------------------------------------------------
    # CRÍTICO: Fuerza a url_for a usar HTTPS para compatibilidad con Ngrok/Flutter
    # -----------------------------------------------------------------------
    denuncia['foto_url'] = url_for('uploaded_file', filename=denuncia['foto_path'], _external=True, _scheme='https')
    
    # Formatear la ubicación como objeto JSON
    denuncia['ubicacion'] = {
        "lat": denuncia.pop('ubicacion_lat'),
        "lng": denuncia.pop('ubicacion_lng'),
    }
    denuncia.pop('foto_path') # Oculta la ruta interna
    return denuncia

# --- ENDPOINTS ---

# Endpoint para servir archivos estáticos (imágenes)
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    """Permite acceder a los archivos guardados en la carpeta 'uploads'."""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

## [cite_start]1. POST /api/denuncias -> Crea una denuncia con multipart/form-data [cite: 19]
@app.route('/api/denuncias', methods=['POST'])
def crear_denuncia():
    # Depuración
    print(f"\nArchivos (request.files): {request.files.keys()}") 
    
    # 1. Validación de Foto
    if 'foto' not in request.files:
        return jsonify({'error': 'Falta el campo de la foto.'}), 400
    
    foto = request.files['foto']
    
    # 2. Extracción de datos de texto
    correo = request.form.get('correo')
    descripcion = request.form.get('descripcion')
    ubicacion_lat = request.form.get('ubicacion_lat')
    ubicacion_lng = request.form.get('ubicacion_lng')
    
    # 3. Validaciones de Campos Faltantes
    if not correo or not descripcion or not ubicacion_lat or not ubicacion_lng:
        # [cite_start]Retorna código HTTP 400 adecuado [cite: 37]
        return jsonify({'error': 'Faltan campos obligatorios (correo, descripcion, ubicacion).'}), 400

    # 4. Guardar la foto
    ext = os.path.splitext(foto.filename)[1] if foto.filename else '.jpg'
    timestamp_name = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    random_hex = os.urandom(4).hex()
    filename = secure_filename(f"{timestamp_name}_{random_hex}{ext}")
    
    foto_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    foto.save(foto_path)

    # 5. Persistir en SQLite
    try:
        conn = get_db_connection()
        cursor = conn.execute(
            'INSERT INTO denuncias (correo, descripcion, ubicacion_lat, ubicacion_lng, foto_path) VALUES (?, ?, ?, ?, ?)',
            (correo, descripcion, float(ubicacion_lat), float(ubicacion_lng), filename)
        )
        conn.commit()
        denuncia_id = cursor.lastrowid
        conn.close()

        # [cite_start]Retorna código HTTP 201 Created [cite: 37]
        return jsonify({
            'message': 'Denuncia creada con éxito.',
            'id': denuncia_id,
            'foto_url': url_for('uploaded_file', filename=filename, _external=True, _scheme='https')
        }), 201

    except ValueError:
        return jsonify({'error': 'La ubicación (lat/lng) debe ser un valor numérico.'}), 400
    except Exception as e:
        return jsonify({'error': f'Error interno del servidor: {str(e)}'}), 500

## [cite_start]2. GET /api/denuncias -> Lista de denuncias [cite: 19]
@app.route('/api/denuncias', methods=['GET'])
def listar_denuncias():
    conn = get_db_connection()
    denuncias = conn.execute('SELECT * FROM denuncias ORDER BY fecha DESC').fetchall()
    conn.close()

    denuncias_list = [row_to_dict(denuncia) for denuncia in denuncias]

    return jsonify(denuncias_list), 200

## [cite_start]3. GET /api/denuncias/<id> -> Detalle por id [cite: 19]
@app.route('/api/denuncias/<int:id>', methods=['GET'])
def detalle_denuncia(id):
    conn = get_db_connection()
    denuncia = conn.execute('SELECT * FROM denuncias WHERE id = ?', (id,)).fetchone()
    conn.close()

    if denuncia is None:
        return jsonify({'error': f'Denuncia con ID {id} no encontrada.'}), 404 # 404 Not Found [cite: 37]

    denuncia_dict = row_to_dict(denuncia)

    return jsonify(denuncia_dict), 200

# --- EJECUCIÓN ---
if __name__ == '__main__':
    # [cite_start]Flask debe levantarse en http://localhost:5000 [cite: 23]
    app.run(host='0.0.0.0', port=5000, debug=True)