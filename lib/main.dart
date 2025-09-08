import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'data/local/local_db.dart';
import 'widgets/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa la DB (crea tablas y seed si es primera vez)
  await LocalDb().database;
  runApp(const KeyCashOfflineApp());
}

class KeyCashOfflineApp extends StatelessWidget {
  const KeyCashOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadToday()),
      ],
      child: MaterialApp(
        title: 'KeyCash Offline',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1976D2),
          brightness: Brightness.light,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1976D2),
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}