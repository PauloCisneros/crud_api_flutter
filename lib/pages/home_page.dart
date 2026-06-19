import 'package:flutter/material.dart';
import '../db/mongo_database.dart';
import '../models/libro.dart';
import 'form_page.dart';
import 'detail_page.dart';
import 'about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // Controla la pestaña activa

  final GlobalKey<_EstadisticasTabState> _statsKey = GlobalKey();

  // Lista de títulos para el AppBar según la pestaña
  final List<String> _titles = [
    'Mi Colección Local',
    'Explorar Open Library',
    'Estadísticas',
    'Acerca de la App',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      // Cuerpo dinámico según la pestaña seleccionada
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ColeccionLocalTab(onRefreshRequest: () => setState(() {})),
          const _ExplorarApiTab(),
          _EstadisticasTab(key: _statsKey),
          const AboutPage(),
          
        ],
      ),
      // Menú de navegación inferior elegante (Material 3)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Colección',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar API',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Acerca de la App',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 1. PESTAÑA: COLECCIÓN LOCAL (CRUD MONGODB)
// =========================================================================
class _ColeccionLocalTab extends StatefulWidget {
  final VoidCallback onRefreshRequest;
  const _ColeccionLocalTab({required this.onRefreshRequest});

  @override
  State<_ColeccionLocalTab> createState() => _ColeccionLocalTabState();
}

class _ColeccionLocalTabState extends State<_ColeccionLocalTab> {
  late Future<List<Libro>> librosFuture;

  @override
  void initState() {
    super.initState();
    _cargarLibros();
  }

  void _cargarLibros() {
    librosFuture = MongoDatabase.getLibrosGuardados();
  }

  Future<void> _refrescar() async {
    setState(() {
      _cargarLibros();
    });
    widget.onRefreshRequest(); // Notifica al componente padre para actualizar estadísticas
  }

  void _confirmarEliminar(Libro libro) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Libro'),
        content: Text('¿Seguro que deseas eliminar "${libro.titulo}" de tu colección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await MongoDatabase.deleteLibro(libro.id);
              _refrescar();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormPage()), // Para crear uno manual
          );
          _refrescar();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Libro>>(
        future: librosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error en MongoDB: ${snapshot.error}'));
          }
          final libros = snapshot.data ?? [];
          if (libros.isEmpty) {
            return const Center(child: Text('Tu colección está vacía. ¡Explora la API para guardar libros!'));
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView.builder(
              itemCount: libros.length,
              itemBuilder: (context, index) {
                final libro = libros[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: libro.imagen.isNotEmpty
                        ? Image.network(libro.imagen, width: 45, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.book))
                        : const Icon(Icons.book),
                    title: Text(
                      libro.titulo, 
                      style: const TextStyle(fontWeight: FontWeight.bold), // <- CORREGIDO AQUÍ
                    ),
                    subtitle: Text('${libro.autor} (${libro.anio})'),
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
                            _refrescar();
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
          );
        },
      ),
    );
  }
}

// =========================================================================
// 2. PESTAÑA: EXPLORAR API (BUSCADOR OPEN LIBRARY + IMPORTACIÓN)
// =========================================================================
class _ExplorarApiTab extends StatefulWidget {
  const _ExplorarApiTab();

  @override
  State<_ExplorarApiTab> createState() => _ExplorarApiTabState();
}

class _ExplorarApiTabState extends State<_ExplorarApiTab> {
  final _searchCtrl = TextEditingController();
  List<Libro> _resultados = [];
  bool _cargando = false;

  void _buscar() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() => _cargando = true);
    final resultados = await MongoDatabase.buscarEnOpenLibrary(_searchCtrl.text);
    setState(() {
      _resultados = resultados;
      _cargando = false;
    });
  }

  void _importarLibro(Libro libro) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    await MongoDatabase.insertLibro(libro);
    
    if (!mounted) return;
    Navigator.pop(context); // Cierra el loading
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${libro.titulo}" guardado en MongoDB Atlas')),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar libros en Open Library...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _buscar,
                icon: const Icon(Icons.send),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_cargando) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_cargando && _resultados.isEmpty)
            const Expanded(child: Center(child: Text('Escribe un título o autor para buscar.'))),
          if (!_cargando && _resultados.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _resultados.length,
                itemBuilder: (context, index) {
                  final libro = _resultados[index];
                  return Card(
                    color: const Color.fromARGB(255, 5, 7, 83).withOpacity(0.05),
                    child: ListTile(
                      leading: libro.imagen.isNotEmpty
                          ? Image.network(libro.imagen, width: 45, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.book))
                          : const Icon(Icons.book),
                      title: Text(libro.titulo),
                      subtitle: Text(libro.autor),
                      trailing: IconButton(
                        icon: const Icon(Icons.cloud_download, color: Colors.teal),
                        tooltip: 'Guardar en MongoDB',
                        onPressed: () => _importarLibro(libro),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. PESTAÑA: ESTADÍSTICAS (KPIs EN TIEMPO REAL DESDE MONGO)
// =========================================================================
class _EstadisticasTab extends StatefulWidget {
  const _EstadisticasTab({super.key});

  @override
  State<_EstadisticasTab> createState() => _EstadisticasTabState();
}

class _EstadisticasTabState extends State<_EstadisticasTab> {
  late Future<List<Libro>> _estadisticasFuture;

  @override
  void initState() {
    super.initState();
    _estadisticasFuture = MongoDatabase.getLibrosGuardados();
  }

  // Método para refrescar los datos manualmente
  void _refrescarDatos() {
    setState(() {
      _estadisticasFuture = MongoDatabase.getLibrosGuardados();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos RefreshIndicator para que el usuario pueda deslizar hacia abajo y actualizar
    return RefreshIndicator(
      onRefresh: () async => _refrescarDatos(),
      child: FutureBuilder<List<Libro>>(
        future: _estadisticasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final libros = snapshot.data ?? [];
          final totalLibros = libros.length;
          
          // Calcular autores únicos
          final autoresUnicos = libros.map((l) => l.autor).toSet().length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _kpiCard('Libros Guardados', '$totalLibros', Icons.menu_book, Colors.blue),
                _kpiCard('Autores Distintos', '$autoresUnicos', Icons.person, Colors.orange),
                _kpiCard('Sincronizados', '$totalLibros', Icons.cloud_done, Colors.green),
                _kpiCard('Versión API', 'v1.0 (JSON)', Icons.api, Colors.purple),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 4. PESTAÑA: ACERCA DE (DATOS DEL PROYECTO)
// =========================================================================
class _AcercaDeTab extends StatelessWidget {
  const _AcercaDeTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.teal,
              child: Icon(Icons.developer_mode, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gestor para tus Libros',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplicación Híbrida Flutter conectada a Open Library API y MongoDB Atlas para la persistencia permanente en la nube.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Divider(height: 40),
            const ListTile(
              leading: Icon(Icons.code),
              title: Text('Desarrollador'),
              subtitle: Text('Paulo Cisneros / Estudiante'),
            ),
            const ListTile(
              leading: Icon(Icons.storage),
              title: Text('Base de Datos'),
              subtitle: Text('MongoDB Atlas'),
            ),
          ],
        ),
      ),
    );
  }
}