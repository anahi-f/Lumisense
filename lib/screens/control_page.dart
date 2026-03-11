// ============================================
// control_page.dart (COMPLETO)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../Bluetooth/global.dart';

const Color moradoLumisense = Color(0xFFd0a3cf);
final ValueNotifier<bool> ledStateNotifier = ValueNotifier<bool>(false);

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> with WidgetsBindingObserver {
  // Estos valores ahora se obtienen del BluetoothManager global
  Color get selectedColor => bluetooth.selectedColor;
  set selectedColor(Color value) => bluetooth.selectedColor = value;

  double get intensity => bluetooth.intensity;
  set intensity(double value) => bluetooth.intensity = value;

  double get speed => bluetooth.speed;
  set speed(double value) => bluetooth.speed = value;

  String? get modoActivo => bluetooth.modoActivo;

  @override
  void initState() {
    super.initState();
    bluetooth.connectionNotifier.addListener(_onConnectionChange);
    WidgetsBinding.instance.addObserver(this);
    // Inicializar ledStateNotifier con el valor guardado en bluetooth
    ledStateNotifier.value = bluetooth.ledOn;
  }

  void _onConnectionChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    bluetooth.connectionNotifier.removeListener(_onConnectionChange);
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

  String getSpeedLabel(double value) {
    if (value <= 13) return "Lento";
    if (value <= 27) return "Normal";
    return "Rápido";
  }

  void abrirSelectorColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
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
            if (ledStateNotifier.value) {
              bluetooth.send("COLOR:${color.red},${color.green},${color.blue}");
            }
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
    bool isConnected = bluetooth.connectionNotifier.value;
    bool controlesHabilitados = isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control LED"),
        backgroundColor: Colors.black,
        actions: [
          if (modoActivo != null && controlesHabilitados)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: moradoLumisense.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: moradoLumisense),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    modoActivo == "Emociones"
                        ? Icons.emoji_emotions
                        : modoActivo == "Respiración"
                        ? Icons.air
                        : Icons.waves,
                    color: moradoLumisense,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    modoActivo!,
                    style: const TextStyle(
                      color: moradoLumisense,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.red,
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
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? "Conectado" : "Desconectado",
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
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
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Botón Bluetooth
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: AbsorbPointer(
                  absorbing: isConnected,
                  child: Opacity(
                    opacity: isConnected ? 0.7 : 1.0,
                    child: ElevatedButton.icon(
                      onPressed: isConnected
                          ? null
                          : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: true,
                          enableDrag: true,
                          backgroundColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(25)),
                          ),
                          builder: (_) => const BluetoothSheet(),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      icon: Icon(
                        Icons.bluetooth,
                        color: isConnected ? Colors.green : Colors.white,
                      ),
                      label: Text(
                        isConnected ? "Conectado" : "Conectar Bluetooth",
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isConnected ? Colors.green : moradoLumisense,
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
                ),
              ),

              // Estado de conexión
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: modoActivo != null
                        ? moradoLumisense.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: modoActivo != null ? moradoLumisense : Colors.green,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        modoActivo != null ? Icons.info : Icons.check_circle,
                        color: modoActivo != null ? moradoLumisense : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        modoActivo != null
                            ? "Modo $modoActivo activo"
                            : "ESP32 Conectado",
                        style: TextStyle(
                          color: modoActivo != null ? moradoLumisense : Colors.green,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Sin conexión Bluetooth",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Encendido/Apagado
              AbsorbPointer(
                absorbing: !controlesHabilitados,
                child: Opacity(
                  opacity: controlesHabilitados ? 1.0 : 0.5,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: ledStateNotifier,
                    builder: (context, ledOn, child) {
                      // Sincronizar con bluetooth.ledOn
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (bluetooth.ledOn != ledOn) {
                          bluetooth.ledOn = ledOn;
                        }
                      });
                      return Card(
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
                          onChanged: controlesHabilitados
                              ? (value) async {
                            ledStateNotifier.value = value;
                            bluetooth.ledOn = value; // guardar en global
                            if (value) {
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
                          }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón de color
              if (modoActivo != "Emociones") ...[
                AbsorbPointer(
                  absorbing: !controlesHabilitados,
                  child: Opacity(
                    opacity: controlesHabilitados ? 1.0 : 0.5,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: ledStateNotifier,
                      builder: (context, ledOn, child) {
                        return AbsorbPointer(
                          absorbing: !ledOn,
                          child: Opacity(
                            opacity: ledOn ? 1.0 : 0.5,
                            child: ElevatedButton.icon(
                              onPressed: (modoActivo == null ||
                                  modoActivo == "Respiración" ||
                                  modoActivo == "Ola") &&
                                  ledOn &&
                                  controlesHabilitados
                                  ? abrirSelectorColor
                                  : null,
                              icon: const Icon(Icons.color_lens),
                              label: const Text("Seleccionar Color"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (modoActivo == null ||
                                    modoActivo == "Respiración" ||
                                    modoActivo == "Ola") &&
                                    ledOn &&
                                    controlesHabilitados
                                    ? moradoLumisense
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Intensidad
              AbsorbPointer(
                absorbing: !controlesHabilitados,
                child: Opacity(
                  opacity: controlesHabilitados ? 1.0 : 0.5,
                  child: Column(
                    children: [
                      const Text(
                        "Intensidad",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: ledStateNotifier,
                        builder: (context, ledOn, child) {
                          return AbsorbPointer(
                            absorbing: !ledOn,
                            child: Opacity(
                              opacity: ledOn ? 1.0 : 0.5,
                              child: Column(
                                children: [
                                  Slider(
                                    value: intensity,
                                    min: 0,
                                    max: 100,
                                    divisions: 4,
                                    activeColor: moradoLumisense,
                                    inactiveColor: moradoLumisense.withOpacity(0.3),
                                    onChanged: ledOn && controlesHabilitados
                                        ? (value) {
                                      setState(() {
                                        intensity = value;
                                      });
                                      int espValue = (value / 10).round(); // 0-100 → 0-10
                                      bluetooth.send("INT:$espValue");
                                    }
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [0, 25, 50, 75, 100].map((step) {
                                      bool isCurrent = intensity.toInt() == step;
                                      return Text(
                                        '$step%',
                                        style: TextStyle(
                                          color: isCurrent ? moradoLumisense : Colors.grey,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  Text(
                                    "${intensity.toInt()}%",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Velocidad
              AbsorbPointer(
                absorbing: !controlesHabilitados,
                child: Opacity(
                  opacity: controlesHabilitados ? 1.0 : 0.5,
                  child: Column(
                    children: [
                      const Text(
                        "Velocidad",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: ledStateNotifier,
                        builder: (context, ledOn, child) {
                          final velocidadHabilitada = ledOn &&
                              (modoActivo == null || modoActivo == "Ola") &&
                              controlesHabilitados;

                          return AbsorbPointer(
                            absorbing: !velocidadHabilitada,
                            child: Opacity(
                              opacity: velocidadHabilitada ? 1.0 : 0.5,
                              child: Column(
                                children: [
                                  Slider(
                                    value: speed,
                                    min: 0,
                                    max: 40,
                                    divisions: 2,  // 3 posiciones: 0, 20, 40
                                    activeColor: velocidadHabilitada
                                        ? moradoLumisense
                                        : Colors.grey,
                                    inactiveColor:
                                    moradoLumisense.withOpacity(0.3),
                                    onChanged: velocidadHabilitada
                                        ? (value) {
                                      setState(() {
                                        speed = value;
                                      });
                                      // Convertir posición a valor real para enviar
                                      int realValue;
                                      if (value <= 10) realValue = 1;      // Lento
                                      else if (value <= 30) realValue = 20; // Normal
                                      else realValue = 40;                  // Rápido
                                      bluetooth.send("SPEED:$realValue");
                                    }
                                        : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Lento",
                                          style: TextStyle(
                                            color: velocidadHabilitada && speed <= 10
                                                ? moradoLumisense
                                                : (velocidadHabilitada
                                                ? Colors.white70
                                                : Colors.grey),
                                            fontWeight: speed <= 10
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          "Normal",
                                          style: TextStyle(
                                            color: velocidadHabilitada &&
                                                speed > 10 && speed <= 30
                                                ? moradoLumisense
                                                : (velocidadHabilitada
                                                ? Colors.white70
                                                : Colors.grey),
                                            fontWeight: (speed > 10 && speed <= 30)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          "Rápido",
                                          style: TextStyle(
                                            color: velocidadHabilitada && speed > 30
                                                ? moradoLumisense
                                                : (velocidadHabilitada
                                                ? Colors.white70
                                                : Colors.grey),
                                            fontWeight: speed > 30
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: velocidadHabilitada
                                              ? moradoLumisense.withOpacity(0.2)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          getSpeedLabel(speed),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: velocidadHabilitada
                                                ? moradoLumisense
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        speed <= 10 ? "1" : (speed <= 30 ? "20" : "40"),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: velocidadHabilitada
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (modoActivo != null && controlesHabilitados)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: moradoLumisense.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: moradoLumisense.withOpacity(0.3)),
                    ),
                    child: Text(
                      modoActivo == "Emociones"
                          ? 'Modo Emociones: Solo puedes cambiar la intensidad'
                          : modoActivo == "Respiración"
                          ? 'Modo Respiración: Puedes cambiar color e intensidad'
                          : 'Modo Ola: Puedes cambiar color, velocidad e intensidad',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================
//                HOJA DE BLUETOOTH (MODAL)
// =================================================

class BluetoothSheet extends StatefulWidget {
  const BluetoothSheet({super.key});

  @override
  State<BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<BluetoothSheet> {
  List<BluetoothDevice> devices = [];
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
        // FILTRO: mismo criterio que en la pantalla principal
        final deviceName = device.name ?? "";
        if (deviceName.contains("LumiSense") || deviceName.contains("ESP32")) {
          if (mounted) {
            setState(() {
              if (!devices.any((d) => d.address == device.address)) {
                devices.add(device);
                debugPrint("Dispositivo agregado: ${device.name ?? 'Desconocido'}");
              }
            });
          }
        }
      });

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

  Future<void> connectToDevice(BluetoothDevice device) async {
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            scanning ? "Buscando dispositivos..." : "Dispositivos encontrados",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (scanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(moradoLumisense),
              ),
            ),
          const SizedBox(height: 10),
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
                final deviceName = device.name ?? "ESP32 Desconocido";
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
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "MAC: ${device.address}",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: connecting
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(moradoLumisense),
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