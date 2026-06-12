class Libro {
  final String id;
  final String titulo;
  final String autor;
  final String anio;
  final String imagen;
  final String descripcion;

  Libro({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.anio,
    required this.imagen,
    required this.descripcion,
  });

  // Constructor 1: Para cuando los datos vienen de la API de Open Library
  factory Libro.fromJsonAPI(Map<String, dynamic> json) {
    final autores = json['author_name'] as List?;
    final coverId = json['cover_i'];
    
    return Libro(
      // Usamos la propiedad 'key' de Open Library o un ID temporal como ID único
      id: (json['key'] ?? '').toString().replaceAll('/works/', ''), 
      titulo: json['title'] ?? 'Sin título',
      autor: (autores != null && autores.isNotEmpty) ? autores.first.toString() : 'Autor Desconocido',
      anio: json['first_publish_year']?.toString() ?? 'N/A',
      imagen: coverId != null ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg' : '',
      descripcion: 'Importado desde Open Library.',
    );
  }

  // Constructor 2: Para cuando leemos los datos guardados desde tu MONGODB
  factory Libro.fromMongoMap(Map<String, dynamic> map) {
    return Libro(
      id: map['_id'].toString(),
      titulo: map['titulo'] ?? '',
      autor: map['autor'] ?? '',
      anio: map['anio'] ?? '',
      imagen: map['imagen'] ?? '',
      descripcion: map['descripcion'] ?? '',
    );
  }

  // Para guardar o actualizar en tu MongoDB
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'titulo': titulo,
      'autor': autor,
      'anio': anio,
      'imagen': imagen,
      'descripcion': descripcion,
    };
  }
}