import 'dart:convert'; // Para jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Para peticiones HTTP reales
import '../db/mongo_database.dart';
import '../models/libro.dart';


class ApiExplorerPage extends StatefulWidget {
  const ApiExplorerPage({super.key});

  @override
  State<ApiExplorerPage> createState() => _ApiExplorerPageState();
}

class _ApiExplorerPageState extends State<ApiExplorerPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<Libro> _librosApi = [];
  bool _cargandoInicial = false;
  bool _cargandoMas = false;
  
  int _paginaActual = 1;
  String _ultimaBusqueda = "";

  @override
  void initState() {
    super.initState();
    
    // Listener para detectar el final de la lista y pedir más páginas a Open Library
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        _cargarSiguientePagina();
      }
    });
  }

  // Primera consulta a la API
  Future<void> _nuevaBusqueda() async {
    final texto = _searchCtrl.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _cargandoInicial = true;
      _librosApi.clear();
      _paginaActual = 1;
      _ultimaBusqueda = texto;
    });

    try {
      final resultados = await _buscarEnOpenLibraryPaginado(texto, _paginaActual);
      setState(() {
        _librosApi = resultados;
        _cargandoInicial = false;
      });
    } catch (e) {
      setState(() => _cargandoInicial = false);
      _mostrarSnackBar('Error al consultar la API');
    }
  }

  // Disparado por el Infinite Scroll para traer más páginas
  Future<void> _cargarSiguientePagina() async {
    if (_cargandoMas || _cargandoInicial || _ultimaBusqueda.isEmpty) return;

    setState(() => _cargandoMas = true);
    int proximaPagina = _paginaActual + 1;

    try {
      final nuevosLibros = await _buscarEnOpenLibraryPaginado(_ultimaBusqueda, proximaPagina);
      
      setState(() {
        if (nuevosLibros.isNotEmpty) {
          _librosApi.addAll(nuevosLibros);
          _paginaActual = proximaPagina;
        }
        _cargandoMas = false;
      });
    } catch (e) {
      setState(() => _cargandoMas = false);
    }
  }

  // MÉTODO LIMPIO Y CORREGIDO: Hace la petición HTTP real paginada
  Future<List<Libro>> _buscarEnOpenLibraryPaginado(String query, int page) async {
    final url = Uri.https('openlibrary.org', '/search.json', {
      'q': query,
      'limit': '10',
      'page': page.toString(),
    });

    try {
      final response = await http.get(url);

      // Busca esta sección dentro de api_explorer_page.dart
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];

        // CAMBIA ESTA LÍNEA: Usa 'fromJsonAPI' en lugar de 'fromJson'
        return docs.map((json) => Libro.fromJsonAPI(json)).toList();
      }
    } catch (e) {
      debugPrint("Error en HTTP GET: $e");
    }
    
    return []; 
  }

  // Acción del botón guardar: Almacena el registro en MongoDB Atlas
  Future<void> _guardarEnMongo(Libro libro) async {
    // Mostramos un indicador de procesamiento circular
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await MongoDatabase.insertLibro(libro);
      if (!mounted) return;
      Navigator.pop(context); // Quita el loader
      _mostrarSnackBar('¡"${libro.titulo}" guardado en MongoDB Atlas!');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarSnackBar('Error al guardar: $e');
    }
  }

  void _mostrarSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador Global (API)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Input de Buscador
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por título, autor o saga...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.travel_explore),
                    ),
                    onSubmitted: (_) => _nuevaBusqueda(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _nuevaBusqueda,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Control de Estados de Interfaz
            if (_cargandoInicial)
              const Expanded(child: Center(child: CircularProgressIndicator())),
              
            if (!_cargandoInicial && _librosApi.isEmpty)
              const Expanded(
                child: Center(child: Text('No hay resultados. Realiza una búsqueda global.')),
              ),

            if (!_cargandoInicial && _librosApi.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _librosApi.length + (_cargandoMas ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _librosApi.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final libro = _librosApi[index];
                    return Card(
                      color: Colors.blue.withOpacity(0.02),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: libro.imagen.isNotEmpty
                            ? Image.network(libro.imagen, width: 45, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.book))
                            : const Icon(Icons.book),
                        title: Text(libro.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${libro.autor} (${libro.anio})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.cloud_upload, color: Colors.blueAccent, size: 28),
                          tooltip: 'Guardar en MongoDB Atlas',
                          onPressed: () => _guardarEnMongo(libro),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}