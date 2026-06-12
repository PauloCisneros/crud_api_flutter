import 'package:flutter/material.dart';
import '../db/mongo_database.dart';
import '../models/libro.dart';
import 'form_page.dart';
import 'detail_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final ScrollController _scrollController = ScrollController();
  
  List<Libro> _todosLosLibros = []; // Guarda el total de la BD
  List<Libro> _librosPaginados = []; // Guarda solo los visibles en pantalla
  
  bool _cargandoBaseDeDatos = true;
  bool _cargandoMasContenido = false;
  
  final int _tamanoPagina = 10; // Cuántos libros cargar por bloque
  int _paginaActual = 1;

  @override
  void initState() {
    super.initState();
    _obtenerDatosDeMongo();
    
    // Escuchar el movimiento del scroll para activar el Infinite Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _cargarMasLibrosLocales();
      }
    });
  }

  // Carga inicial completa desde MongoDB Atlas
  Future<void> _obtenerDatosDeMongo() async {
    setState(() {
      _cargandoBaseDeDatos = true;
      _paginaActual = 1;
    });

    try {
      final datos = await MongoDatabase.getLibrosGuardados();
      setState(() {
        _todosLosLibros = datos;
        // Tomamos el primer bloque de libros (ej: del 0 al 10)
        _librosPaginados = _todosLosLibros.take(_tamanoPagina).toList();
        _cargandoBaseDeDatos = false;
      });
    } catch (e) {
      setState(() => _cargandoBaseDeDatos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al leer MongoDB: $e')),
      );
    }
  }

  // Simulación de carga infinita local (Paginación en memoria)
  void _cargarMasLibrosLocales() {
    // Si ya estamos cargando o ya mostramos todo el total, detenemos la función
    if (_cargandoMasContenido || _librosPaginados.length >= _todosLosLibros.length) return;

    setState(() => _cargandoMasContenido = true);

    // Simulamos un pequeño retraso de red para que se aprecie el indicador visual
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      int inicio = _paginaActual * _tamanoPagina;
      int fin = inicio + _tamanoPagina;

      // Nos aseguramos de no pasarnos del límite del arreglo original
      if (fin > _todosLosLibros.length) {
        fin = _todosLosLibros.length;
      }

      setState(() {
        // Agregamos el nuevo bloque extraído de la lista completa
        _librosPaginados.addAll(_todosLosLibros.sublist(inicio, fin));
        _paginaActual++;
        _cargandoMasContenido = false;
      });
    });
  }

  void _confirmarEliminar(Libro libro) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Libro'),
        content: Text('¿Deseas quitar "${libro.titulo}" de tu colección local?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await MongoDatabase.deleteLibro(libro.id);
              _obtenerDatosDeMongo(); // Recargamos todo tras borrar
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colección Completa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerDatosDeMongo,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormPage()),
          );
          _obtenerDatosDeMongo();
        },
        child: const Icon(Icons.add),
      ),
      body: _cargandoBaseDeDatos
          ? const Center(child: CircularProgressIndicator())
          : _todosLosLibros.isEmpty
              ? const Center(child: Text('No hay libros guardados en tu MongoDB Atlas.'))
              : RefreshIndicator(
                  onRefresh: _obtenerDatosDeMongo,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _librosPaginados.length + (_cargandoMasContenido ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Si el índice alcanza la longitud actual, renderizamos la rueda de carga abajo
                      if (index == _librosPaginados.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final libro = _librosPaginados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: libro.imagen.isNotEmpty
                              ? Image.network(
                                  libro.imagen,
                                  width: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.book),
                                )
                              : const Icon(Icons.book),
                          title: Text(libro.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${libro.autor} — Vol. ${libro.anio}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FormPage(videojuego: libro)),
                                  );
                                  _obtenerDatosDeMongo();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmarEliminar(libro),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DetailPage(videojuego: libro)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}