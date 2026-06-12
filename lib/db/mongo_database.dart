import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:http/http.dart' as http;
import '../models/libro.dart';

class MongoDatabase {
  static Db? _db;
  static DbCollection? _collection;

  // Tu URL corregida con los parámetros correctos de unión (&)
  static const String connectionString =
      '';

  // 1. CONECTAR A MONGODB (Con verificación y protección de reconexión)
  static Future<void> connect() async {
    try {
      if (_db != null && _db!.isConnected) {
        return; // Si ya está conectado, no hace nada
      }

      _db = await Db.create(connectionString);
      await _db!.open();
      _collection = _db!.collection('libros_guardados'); 
      print("¡Conexión exitosa a MongoDB Atlas!");
    } catch (e) {
      print("Error crítico al conectar a MongoDB Atlas: $e");
    }
  }

  // Asegura que la base de datos esté lista antes de cualquier operación CRUD
  static Future<void> _asegurarConexion() async {
    if (_db == null || !_db!.isConnected) {
      print("Socket reiniciado o inexistente. Intentando reconectar de forma segura...");
      await connect();
    }
  }

  // 2. CONSUMIR LA API (No toca la BD, se mantiene igual)
  static Future<List<Libro>> buscarEnOpenLibrary(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.https('openlibrary.org', '/search.json', {
      'q': query,
      'limit': '10',
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> docs = decodedData['docs'] ?? [];
        
        return docs.map((item) => Libro.fromJsonAPI(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      print('Error al consultar la API de Open Library: $e');
    }
    return [];
  }

  // ==========================================
  //         OPERACIONES CRUD PROTEGIDAS
  // ==========================================

  // 3. CREATE
  static Future<void> insertLibro(Libro libro) async {
    try {
      await _asegurarConexion();
      await _collection!.insertOne(libro.toMap());
    } catch (e) {
      print("Error al insertar libro (Socket reset?): $e");
      // Reintento rápido si el socket se cayó
      await _asegurarConexion();
      await _collection!.insertOne(libro.toMap());
    }
  }

  // 4. READ
  static Future<List<Libro>> getLibrosGuardados() async {
    try {
      await _asegurarConexion();
      final data = await _collection!.find().toList();
      return data.map((item) => Libro.fromMongoMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      print("Error al leer libros guardados (Socket reset?): $e");
      // Si dio error, reconectamos y devolvemos una lista limpia o reintentamos
      await _asegurarConexion();
      try {
        final data = await _collection!.find().toList();
        return data.map((item) => Libro.fromMongoMap(Map<String, dynamic>.from(item))).toList();
      } catch (_) {
        return [];
      }
    }
  }

  // 5. UPDATE
  static Future<void> updateLibro(Libro libro) async {
    try {
      await _asegurarConexion();
      await _collection!.updateOne(
        where.eq('_id', libro.id),
        modify
            .set('titulo', libro.titulo)
            .set('autor', libro.autor)
            .set('anio', libro.anio)
            .set('imagen', libro.imagen)
            .set('descripcion', libro.descripcion),
      );
    } catch (e) {
      print("Error al actualizar libro: $e");
    }
  }

  // 6. DELETE
  static Future<void> deleteLibro(dynamic id) async {
    try {
      await _asegurarConexion();
      await _collection!.deleteOne(where.eq('_id', id));
    } catch (e) {
      print("Error al eliminar libro: $e");
    }
  }
}