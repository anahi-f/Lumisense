import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/control_page.dart';
import 'screens/modes_page.dart';
import 'screens/tutorial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verificar si ya vio el tutorial
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool vistoTutorial = prefs.getBool('visto_tutorial') ?? false;

  runApp(LumiSense(mostrarTutorial: !vistoTutorial));
}

class LumiSense extends StatelessWidget {
  final bool mostrarTutorial;

  const LumiSense({super.key, required this.mostrarTutorial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: mostrarTutorial ? const TutorialScreen() : const MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int currentIndex = 0;

  final pages = [
    const ControlPage(),
    const ModesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LumiSense"),
        backgroundColor: Colors.black,
        actions: [
          // Botón de ayuda para repetir tutorial
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorialScreen()),
              );
            },
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: "Control",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "Modos",
          ),
        ],
      ),
    );
  }
}