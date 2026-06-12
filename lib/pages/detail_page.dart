import 'package:flutter/material.dart';
import '../db/mongo_database.dart';
import '../models/libro.dart';
import 'form_page.dart';

class DetailPage extends StatefulWidget {
  // Mantenemos el nombre del parámetro 'videojuego' para que no tengas que cambiar las rutas en tu HomePage
  final Libro videojuego; 

  const DetailPage({super.key, required this.videojuego});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Libro _libro;

  @override
  void initState() {
    super.initState();
    _libro = widget.videojuego;
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar de la Colección'),
        content: Text('¿Seguro que deseas borrar permanentemente "${_libro.titulo}" de MongoDB Atlas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo
              await MongoDatabase.deleteLibro(_libro.id);
              if (!mounted) return;
              Navigator.pop(context); // Regresa al listado principal (Home/Collection)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Libro eliminado correctamente')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Libro'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Botón para Editar
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Editar información',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormPage(videojuego: _libro),
                ),
              );
              // Al regresar del formulario de edición, lo ideal es cerrar el detalle
              // para que la pantalla anterior se refresque por completo desde MongoDB.
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
          // Botón para Eliminar
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Eliminar libro',
            onPressed: _confirmarEliminar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de la Portada/Imagen
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                boxShadow: const [ // <- CORREGIDO: Si decides dejar const, los valores internos deben ser estrictamente literales
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: _libro.imagen.isNotEmpty
                  ? Image.network(
                      _libro.imagen,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.menu_book, size: 80, color: Colors.grey), // <- CORREGIDO: Cambiado de book_placeholder a menu_book
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.menu_book, size: 80, color: Colors.grey),
                    ),
            ),
            
            // Cuerpo de información del Libro
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título principal
                  Text(
                    _libro.titulo,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),

                  // Fila de Autor y Año usando Chips de Material 3
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text(_libro.autor),
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // <- AJUSTADO: Compatibilidad limpia de Material 3
                      ),
                      Chip(
                        avatar: const Icon(Icons.calendar_today, size: 14),
                        label: Text('Año: ${_libro.anio}'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const Divider(height: 35),

                  // Subtítulo de Sinopsis
                  Text(
                    'Sinopsis / Descripción',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),

                  // Texto de la Descripción
                  Text(
                    _libro.descripcion.isNotEmpty 
                        ? _libro.descripcion 
                        : 'Este libro no cuenta con una sinopsis detallada registrada en la colección local.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Identificador único (Metadata de control para MongoDB)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID de Sistema (Atlas): ${_libro.id}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}