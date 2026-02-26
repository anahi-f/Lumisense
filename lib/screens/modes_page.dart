import 'package:flutter/material.dart';

class ModesPage extends StatelessWidget {
  const ModesPage({super.key});

  void _selectMode(BuildContext context, String mode) {
    // Aquí puedes enviar la información a tu ESP32 o navegar a otra pantalla
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modo seleccionado: $mode')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modos de Funcionamiento"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectMode(context, "Emociones"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60), // Botón ancho
              ),
              child: const Text("Modo Emociones"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectMode(context, "Cascada"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text("Modo Cascada"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectMode(context, "Secuencia"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text("Modo Secuencia"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectMode(context, "Ola"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text("Modo Ola"),
            ),
          ],
        ),
      ),
    );
  }
}