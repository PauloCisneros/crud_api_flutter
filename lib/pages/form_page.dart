import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../db/mongo_database.dart';
import '../models/libro.dart';

class FormPage extends StatefulWidget {
  // Cambiado de 'videojuego' a 'videojuego' (o libro) para mantener compatibilidad con tus llamadas previas
  final Libro? videojuego; 
  const FormPage({super.key, this.videojuego});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto para los campos del Libro
  final tituloCtrl = TextEditingController();
  final autorCtrl = TextEditingController();
  final anioCtrl = TextEditingController();
  final imagenCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  bool guardando = false;

  @override
  void initState() {
    super.initState();
    // Si nos pasan un libro, rellenamos los campos automáticamente (Modo Editar)
    final item = widget.videojuego;
    if (item != null) {
      tituloCtrl.text = item.titulo;
      autorCtrl.text = item.autor;
      anioCtrl.text = item.anio;
      imagenCtrl.text = item.imagen;
      descripcionCtrl.text = item.descripcion;
    }
  }

  Future<void> guardar() async {
    // Validar que las reglas del formulario se cumplan
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => guardando = true);

    // Creamos el objeto Libro con los datos de los inputs
    final libro = Libro(
      // Si estamos editando mantenemos su ID, si es nuevo generamos un UUID único
      id: widget.videojuego?.id ?? const Uuid().v4(),
      titulo: tituloCtrl.text.trim(),
      autor: autorCtrl.text.trim(),
      anio: anioCtrl.text.trim(),
      imagen: imagenCtrl.text.trim(),
      descripcion: descripcionCtrl.text.trim(),
    );

    try {
      if (widget.videojuego == null) {
        // C de tu CRUD: Crear en MongoDB
        await MongoDatabase.insertLibro(libro);
        _mostrarSnackBar('Libro creado con éxito');
      } else {
        // U de tu CRUD: Actualizar en MongoDB
        await MongoDatabase.updateLibro(libro);
        _mostrarSnackBar('Libro actualizado con éxito');
      }

      if (!mounted) return;
      Navigator.pop(context); // Regresar a la pantalla anterior tras guardar
    } catch (e) {
      setState(() => guardando = false);
      _mostrarSnackBar('Error al guardar en MongoDB: $e');
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // Widget reutilizable para generar los campos de texto estructurados
  Widget campo(TextEditingController ctrl, String label, {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    // Buenas prácticas: destruir los controladores para liberar memoria RAM
    tituloCtrl.dispose();
    autorCtrl.dispose();
    anioCtrl.dispose();
    imagenCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.videojuego != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Libro' : 'Añadir Libro Manual'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              campo(tituloCtrl, 'Título del Libro'),
              campo(autorCtrl, 'Autor / Escritor'),
              campo(anioCtrl, 'Año de Publicación', type: TextInputType.number),
              campo(imagenCtrl, 'URL de la Portada (Imagen)'),
              campo(descripcionCtrl, 'Sinopsis / Descripción', maxLines: 3),
              const SizedBox(height: 12),
              
              // Botón de acción con indicador de carga
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: guardando ? null : guardar,
                  icon: guardando 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(Icons.save),
                  label: Text(guardando ? 'Procesando en Atlas...' : 'Guardar en Colección'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}