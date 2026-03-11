import 'package:flutter/material.dart';
import '../Bluetooth/global.dart';

const Color moradoLumisense = Color(0xFFd0a3cf);

class ModesPage extends StatefulWidget {
  const ModesPage({super.key});

  @override
  State<ModesPage> createState() => _ModesPageState();
}

class _ModesPageState extends State<ModesPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  void _manejarModo(String modeName, String modeCommand) async {
    if (!bluetooth.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero conecta un dispositivo Bluetooth'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Si el modo ya está activo, lo desactivamos
    if (bluetooth.modoActivo == modeName) {
      await bluetooth.send("MODE:NORMAL");
      bluetooth.modoActivo = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Modo desactivado'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Si no está activo, lo activamos
      await bluetooth.send("MODE:$modeCommand");
      bluetooth.modoActivo = modeName;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 Modo $modeName activado'),
          backgroundColor: moradoLumisense,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Modos de Funcionamiento",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bluetooth.isConnected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: bluetooth.isConnected ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bluetooth.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bluetooth.isConnected ? "Conectado" : "Desconectado",
                  style: TextStyle(
                    color: bluetooth.isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Mensaje de modo activo
            if (bluetooth.modoActivo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: moradoLumisense.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: moradoLumisense),
                ),
                child: Column(
                  children: [
                    Icon(
                      bluetooth.modoActivo == "Emociones"
                          ? Icons.emoji_emotions
                          : bluetooth.modoActivo == "Respiración"
                          ? Icons.air
                          : Icons.waves,
                      color: moradoLumisense,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modo activo: ${bluetooth.modoActivo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      bluetooth.modoActivo == "Emociones"
                          ? 'En la página de control solo podrás cambiar la intensidad'
                          : bluetooth.modoActivo == "Respiración"
                          ? 'En la página de control podrás cambiar color e intensidad'
                          : 'En la página de control podrás cambiar color, velocidad e intensidad',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              const Text(
                "Selecciona un modo de iluminación",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 30),

            // Modo Emociones
            _buildModoButton(
              icon: Icons.emoji_emotions,
              label: "Emociones",
              descripcion: "Colores según tu emoción",
              onTap: () => _manejarModo("Emociones", "EMOCIONES"),
              isActive: bluetooth.modoActivo == "Emociones",
            ),

            const SizedBox(height: 16),

            // Modo Respiración
            _buildModoButton(
              icon: Icons.air,
              label: "Respiración",
              descripcion: "Efecto de respiración suave",
              onTap: () => _manejarModo("Respiración", "RESPIRACION"),
              isActive: bluetooth.modoActivo == "Respiración",
            ),

            const SizedBox(height: 16),

            // Modo Ola
            _buildModoButton(
              icon: Icons.waves,
              label: "Ola",
              descripcion: "Efecto de ola",
              onTap: () => _manejarModo("Ola", "OLA"),
              isActive: bluetooth.modoActivo == "Ola",
            ),

            const SizedBox(height: 20),

            // Mensaje de Bluetooth (solo si no está conectado)
            if (!bluetooth.isConnected)
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Conecta Bluetooth",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget para construir los botones de modo con tooltips
  Widget _buildModoButton({
    required IconData icon,
    required String label,
    required String descripcion,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Tooltip(
      message: isActive
          ? "Presiona para desactivar el modo"
          : "Presiona para activar el modo",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff1E293B),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isActive
                    ? moradoLumisense
                    : moradoLumisense.withOpacity(0.3),
                width: isActive ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icono del modo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: moradoLumisense.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: moradoLumisense,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Textos del modo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Modo $label",
                        style: TextStyle(
                          color: isActive ? moradoLumisense : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icono de estado (check o flecha)
                Icon(
                  isActive ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: isActive ? moradoLumisense : moradoLumisense,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}