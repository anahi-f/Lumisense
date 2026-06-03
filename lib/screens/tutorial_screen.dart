import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const Color moradoLumisense = Color(0xFFd0a3cf);
const Color moradoOscuro = Color(0xFF8a5d8a);

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> pages = [
    {
      'icon': Icons.lightbulb,
      'titulo': 'Bienvenido a LumiSense',
      'descripcion': 'Aplicación para controlar un sistema de luces LED\ndiseñado para terapia sensorial.\n\nCuenta con múltiples modos de iluminación\npara crear el ambiente deseado.',
      'color': moradoLumisense,
    },
    {
      'icon': Icons.bluetooth,
      'titulo': 'Conectar',
      'descripcion': '1. Activa el Bluetooth en tu celular\n2. Presiona el botón "Conectar Bluetooth"\n3. Selecciona "LumiSense ESP32"\n\nEl botón cambiará a color verde cuando\nestés conectado.',
      'color': Colors.blue,
    },
    {
      'icon': Icons.emoji_emotions,
      'titulo': 'Modo Emociones',
      'descripcion': 'Las luces cambian según cómo te sientes:\n\n🔴 Rojo\n🟡 Amarillo\n🔵 Azul',
      'color': Colors.yellow,
    },
    {
      'icon': Icons.air,
      'titulo': 'Modo Respiración',
      'descripcion': 'Efecto de respiración suave que simula\nel ritmo de la inhalación y exhalación.\n\nPuedes personalizar el color y la intensidad\npara crear un ambiente relajante.',
      'color': moradoLumisense,
    },
    {
      'icon': Icons.waves,
      'titulo': 'Modo Ola',
      'descripcion': 'Efecto de onda que recorre la tira de LEDs\ncreando un movimiento fluido.\n\nPuedes ajustar el color, la velocidad\ny la intensidad del efecto.',
      'color': Colors.cyan,
    },
    {
      'icon': Icons.tune,
      'titulo': 'Controles',
      'descripcion': 'En la página "Control" puedes:\n\n• Encender/Apagado las luces\n• Seleccionar colores personalizados\n• Ajustar intensidad (0-100%)\n• Controlar velocidad (Lento/Normal/Rápido)\n\nLos controles se habilitan solo cuando\nhay conexión Bluetooth activa.',
      'color': Colors.green,
    },
    {
      'icon': Icons.bluetooth_disabled,
      'titulo': 'Desconexión Bluetooth',
      'descripcion': 'Cuando estés conectado, en la pantalla de Control\nverás un botón rojo con el texto "Desconectar".\n\nPúlsalo para finalizar la conexión de forma segura.\n\nTambién puedes desconectar desde la pantalla\nde conexión principal con el ícono 🔴.',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            children: pages.map((page) {
              return Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: (page['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: page['color'] as Color,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        page['icon'],
                        size: 80,
                        color: page['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      page['titulo'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      page['descripcion'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          // Puntitos indicadores
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentPage == index ? 12 : 8,
                  height: currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: currentPage == index ? moradoLumisense : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Botón cerrar (saltar tutorial)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('visto_tutorial', true);
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainMenu()),
                        (route) => false,
                  );
                }
              },
            ),
          ),
          // Botones Anterior/Siguiente/Comenzar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text(
                      "← Anterior",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                else
                  const SizedBox(width: 70),
                if (currentPage < pages.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moradoLumisense,
                      foregroundColor: moradoOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Siguiente →",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('visto_tutorial', true);
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainMenu()),
                              (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "¡Comenzar!",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}