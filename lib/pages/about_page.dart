import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca del Proyecto'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================================
            // SECCIÓN 1: INTEGRANTES DEL EQUIPO
            // =========================================================================
            _buildSectionTitle(context, 'Integrantes del Equipo', Icons.people),
            const SizedBox(height: 8),
            _buildTeamMember('Paulo Cinseros', 'Estudiante', 'A01234567'),
            
            const Divider(height: 32),

            // =========================================================================
            // SECCIÓN 2: API CONSUMIDA
            // =========================================================================
            _buildSectionTitle(context, 'API Externa Consumida', Icons.api),
            const SizedBox(height: 8),
            const Card(
              elevation: 0,
              color: Colors.blueAccent,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Library REST API',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Se utiliza el endpoint `/search.json?q={query}&page={page}` de la organización Open Library. Es un servicio abierto, público y gratuito que provee metadatos bibliográficos globales de millones de libros en tiempo real mediante peticiones HTTP GET estructuradas en formato JSON.',
                      style: TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 32),

            // =========================================================================
            // SECCIÓN 3: EXPLICACIÓN TÉCNICA (ARQUITECTURA)
            // =========================================================================
            _buildSectionTitle(context, 'Explicación Técnica & Arquitectura', Icons.developer_board),
            const SizedBox(height: 8),
            _buildTechnicalBullet(
              'Arquitectura Híbrida', 
              'La aplicación desacopla la lectura masiva de datos y la persistencia privada. El usuario explora el inventario global desde un servidor HTTP externo sin penalizar la infraestructura propia.',
            ),
            _buildTechnicalBullet(
              'Persistencia NoSQL', 
              'Para la base de datos local y CRUD, se implementa MongoDB Atlas a través del driver nativo `mongo_dart`. Los libros se transforman de esquemas JSON crudos de la API a documentos flexibles BSON almacenados de forma permanente en la nube.',
            ),
            _buildTechnicalBullet(
              'Infinite Scrolling Dinámico', 
              'Optimización de memoria en UI a través de `ScrollController`. En la API se realiza paginación por red (`&page=n`), mientras que en la colección local se efectúa una segmentación de arreglos en memoria con operadores Dart (`take/sublist`) para evitar lag.',
            ),

            const Divider(height: 32),

            // =========================================================================
            // SECCIÓN 4: CAPTURAS DE PANTALLA (CARRUSEL INMORTAL)
            // =========================================================================
            _buildSectionTitle(context, 'Capturas de Pantalla de la App', Icons.photo_library),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildScreenshotCard('Vista Home & Colección', Icons.bookmark, Colors.amber[100]!),
                  _buildScreenshotCard('Buscador e Infinite Scroll', Icons.travel_explore, Colors.blue[100]!),
                  _buildScreenshotCard('Formulario Crear/Editar', Icons.edit_note, Colors.green[100]!),
                  _buildScreenshotCard('Módulo de Estadísticas', Icons.pie_chart, Colors.purple[100]!),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA MANTENER EL CÓDIGO LIMPIO ---

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTeamMember(String name, String role, String id) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_pin)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role),
        trailing: Text(id, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildTechnicalBullet(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0), // <- CORREGIDO AQUÍ
            child: Icon(Icons.check_circle, size: 16, color: Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotCard(String name, IconData mockIcon, Color bgColor) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(mockIcon, size: 48, color: Colors.black54),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              name,
              textAlign: TextAlign.center, // <- CORREGIDO AQUÍ
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          )
        ], // <- TEXTO DE ERROR REMOVIDO AQUÍ
      ),
    );
  }
}