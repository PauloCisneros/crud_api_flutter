import 'package:flutter/material.dart';
import 'db/mongo_database.dart';
import 'pages/home_page.dart'; // O 'views/home_page.dart' según tu estructura de carpetas

void main() async {
  // OBLIGATORIO: Inicializa los canales nativos de Flutter antes de llamadas asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa la conexión a MongoDB Atlas al arrancar la app
    await MongoDatabase.connect();
    print("Conexión exitosa a MongoDB Atlas");
  } catch (e) {
    print("Error crítico al conectar a MongoDB: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestor Híbrido de Libros',
      
      // Configuración de Estilo Global (Material 3 con paleta verde/teal)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        // Estilo uniforme para los AppBars de toda la app
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      // La app arranca directo en tu menú principal (Dashboard)
      home: const HomePage(),
    );
  }
}