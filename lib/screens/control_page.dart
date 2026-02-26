import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../Bluetooth/global.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

const Color moradoLumisense = Color(0xFFd0a3cf); // Morado pastel clarito

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool ledOn = false;
  Color selectedColor = Colors.blue;
  double intensity = 30;
  double speed = 20;

  /// ================= COLOR PICKER =================
  void openColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1E293B),
        title: const Text(
          "Seleccionar Color",
          style: TextStyle(color: Colors.white),
        ),
        content: ColorPicker(
          pickerColor: selectedColor,
          onColorChanged: (color) {
            setState(() {
              selectedColor = color;
            });
            bluetooth.send("COLOR:${color.red},${color.green},${color.blue}");
          },
          pickerAreaHeightPercent: 0.8,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: moradoLumisense,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cerrar"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control LED"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// BLUETOOTH BUTTON - Morado
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: true,
                      enableDrag: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      builder: (_) => const BluetoothSheet(),
                    );
                  },
                  icon: Icon(
                    Icons.bluetooth,
                    color: bluetooth.isConnected ? Colors.green : Colors.white,
                  ),
                  label: Text(
                    bluetooth.isConnected ? "Conectado" : "Conectar Bluetooth",
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bluetooth.isConnected ? Colors.green : moradoLumisense,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    shadowColor: moradoLumisense.withOpacity(0.4),
                  ),
                ),
              ),

              /// Estado de conexión
              if (bluetooth.isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text("ESP32 Conectado", style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              /// ON OFF
              Card(
                color: const Color(0xff1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SwitchListTile(
                  title: const Text(
                    "Encendido/Apagado",
                    style: TextStyle(color: Colors.white),
                  ),
                  value: ledOn,
                  activeColor: moradoLumisense,
                  onChanged: (value) async {
                    setState(() {
                      ledOn = value;
                    });
                    if (ledOn) {
                      await bluetooth.send("ON");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("LED Encendido"),
                          duration: Duration(seconds: 1),
                          backgroundColor: moradoLumisense,
                        ),
                      );
                    } else {
                      await bluetooth.send("OFF");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("LED Apagado"),
                          duration: Duration(seconds: 1),
                          backgroundColor: moradoLumisense,
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// COLOR BUTTON - Morado
              ElevatedButton.icon(
                onPressed: openColorPicker,
                icon: const Icon(Icons.color_lens),
                label: const Text("Seleccionar Color"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: moradoLumisense,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
              ),

              const SizedBox(height: 30),

              /// INTENSIDAD
              const Text(
                "Intensidad",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: intensity,
                min: 0,
                max: 60,
                divisions: 60,
                activeColor: moradoLumisense,
                inactiveColor: moradoLumisense.withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    intensity = value;
                  });
                  bluetooth.send("INT:${value.toInt()}");
                },
              ),
              Text("${intensity.toInt()}%", style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 20),

              /// VELOCIDAD
              const Text(
                "Velocidad",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: speed,
                min: 0,
                max: 40,
                divisions: 40,
                activeColor: moradoLumisense,
                inactiveColor: moradoLumisense.withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    speed = value;
                  });
                  // Enviar comando SPEED a la tira LED
                  bluetooth.send("SPEED:${value.toInt()}");

                  // Mostrar feedback visual
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Velocidad: ${value.toInt()}"),
                      duration: const Duration(milliseconds: 500),
                      backgroundColor: moradoLumisense,
                    ),
                  );
                },
              ),
              Text("${speed.toInt()}", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

/// =================================================
///                BLUETOOTH SHEET (MODAL)
/// =================================================

class BluetoothSheet extends StatefulWidget {
  const BluetoothSheet({super.key});

  @override
  State<BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<BluetoothSheet> {
  List<ble.BluetoothDevice> devices = [];
  bool scanning = true;
  bool connecting = false;
  String statusMessage = "Buscando dispositivos...";

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  Future<void> startScanning() async {
    setState(() {
      scanning = true;
      devices.clear();
      statusMessage = "Buscando dispositivos...";
    });

    try {
      await bluetooth.startScan((device) {
        if (mounted) {
          setState(() {
            if (!devices.any((d) => d.remoteId == device.remoteId)) {
              devices.add(device);
              print("Dispositivo agregado: ${device.platformName}");
            }
          });
        }
      });

      // Esperar 8 segundos
      await Future.delayed(const Duration(seconds: 8));

      if (mounted) {
        setState(() {
          scanning = false;
          if (devices.isEmpty) {
            statusMessage = "No se encontraron dispositivos";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          scanning = false;
          statusMessage = "Error al escanear";
        });
      }
    }
  }

  Future<void> connectToDevice(ble.BluetoothDevice device) async {
    setState(() {
      connecting = true;
    });

    try {
      await bluetooth.connect(device);

      if (!mounted) return;

      if (bluetooth.isConnected) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ ESP32 conectado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Forzar actualización de la UI en ControlPage
        setState(() {});
      } else {
        throw Exception("No se pudo conectar");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error al conectar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          connecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xff1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),

          // Indicador de arrastre
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 15),

          // Título
          Text(
            scanning ? "Buscando dispositivos..." : "Dispositivos encontrados",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // Barra de progreso
          if (scanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(moradoLumisense),
              ),
            ),

          const SizedBox(height: 10),

          // Lista de dispositivos
          Expanded(
            child: devices.isEmpty && !scanning
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    statusMessage,
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: startScanning,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Buscar nuevamente"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moradoLumisense,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: devices.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final device = devices[index];
                return Card(
                  color: const Color(0xff0F172A),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: moradoLumisense.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: moradoLumisense.withOpacity(0.2),
                      child: const Icon(
                        Icons.memory,
                        color: moradoLumisense,
                      ),
                    ),
                    title: Text(
                      device.platformName.isNotEmpty
                          ? device.platformName
                          : "ESP32 Desconocido",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "ID: ${device.remoteId.toString().substring(0, 8)}...",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: connecting
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(moradoLumisense),
                      ),
                    )
                        : ElevatedButton(
                      onPressed: () => connectToDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moradoLumisense,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: const Text("Conectar"),
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