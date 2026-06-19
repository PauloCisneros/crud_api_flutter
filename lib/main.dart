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
      title: 'Libreria Digital',
      
      // Configuración de Estilo Global
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          brightness: Brightness.light,
          primary: const Color(0xFF008080),
          secondary: const Color(0xFF4DB6AC),
          surface: const Color(0xFFF0FDFB),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF004D40)),
        titleLarge: TextStyle(color: Color(0xFF004D40)),
        ),
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