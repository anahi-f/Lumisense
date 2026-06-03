import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Bluetooth/global.dart';
import 'control_page.dart';

const Color moradoLumisense = Color(0xFFd0a3cf);

class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen>
    with SingleTickerProviderStateMixin {
  String connectionStatus = "Cargando dispositivos emparejados...";
  bool isScanning = false;
  bool isConnecting = false;
  bool loadingPaired = true;

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<BluetoothDevice> pairedDevices = [];
  List<BluetoothDevice> scannedDevices = [];
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bluetooth.isConnected) {
        _navigateToControl();
      } else {
        _loadPairedDevices();
      }
    });
  }

  void _navigateToControl() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ControlPage()),
    );
  }

  // ==================== 1. FILTRO EN EMPAREJADOS ====================
  Future<void> _loadPairedDevices() async {
    setState(() {
      loadingPaired = true;
      connectionStatus = "Obteniendo dispositivos emparejados...";
    });
    try {
      final devices = await bluetooth.getBondedDevices();
      // 🔹 FILTRO: solo mostrar los que contengan "lumisense" (sin importar mayúsculas)
      final filtered = devices.where((d) {
        final name = d.name ?? "";
        return name.toLowerCase().contains("lumisense");
      }).toList();
      setState(() {
        pairedDevices = filtered;
        if (pairedDevices.isNotEmpty) {
          connectionStatus = "Selecciona un dispositivo emparejado";
        } else {
          connectionStatus = "No hay dispositivos LumiSense emparejados. Escanea o conecta manualmente.";
        }
      });
    } catch (e) {
      setState(() {
        connectionStatus = "Error al cargar emparejados: $e";
      });
    } finally {
      setState(() {
        loadingPaired = false;
      });
    }
  }

  // ==================== 2. FILTRO EN ESCANEO ====================
  Future<void> startManualScan() async {
    _scanTimer?.cancel();
    await bluetooth.cancelScan();

    setState(() {
      isScanning = true;
      scannedDevices.clear();
      connectionStatus = "Escaneando... (10 segundos)";
    });

    try {
      await bluetooth.startScan((device) {
        final deviceName = device.name ?? "";
        // 🔹 FILTRO: solo dispositivos que contengan "lumisense"
        if (deviceName.toLowerCase().contains("lumisense")) {
          if (mounted) {
            setState(() {
              if (!scannedDevices.any((d) => d.address == device.address)) {
                scannedDevices.add(device);
                debugPrint("📱 Escaneado (ESP32): ${device.name} (${device.address})");
              }
            });
          }
        }
      });

      _scanTimer = Timer(const Duration(seconds: 10), () async {
        if (mounted) {
          await bluetooth.cancelScan();
          setState(() {
            isScanning = false;
            if (scannedDevices.isEmpty && pairedDevices.isEmpty) {
              connectionStatus =
              "No se encontró ningún LumiSense. Verifica que el ESP32 esté encendido y visible.";
            } else if (scannedDevices.isEmpty && pairedDevices.isNotEmpty) {
              connectionStatus =
              "No se encontraron nuevos, pero tienes dispositivos emparejados abajo.";
            } else {
              connectionStatus = "Selecciona un dispositivo para conectar";
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        connectionStatus = "Error al escanear: $e";
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
      connectionStatus = "Conectando a ${device.name ?? device.address}...";
    });

    try {
      await bluetooth.connect(device);
      if (mounted && bluetooth.isConnected) {
        setState(() {
          connectionStatus = "¡Conectado!";
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Conectado a ${device.name ?? device.address}'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), _navigateToControl);
      } else {
        throw Exception("No se pudo conectar");
      }
    } catch (e) {
      setState(() {
        connectionStatus = "Error al conectar";
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==================== 3. BOTÓN GRANDE DE DESCONEXIÓN ====================
  Future<void> disconnectDevice() async {
    await bluetooth.disconnect();
    setState(() {
      scannedDevices.clear();
      pairedDevices.clear();
      isScanning = false;
      isConnecting = false;
      connectionStatus = "Desconectado. Busca o selecciona un dispositivo.";
    });
    await _loadPairedDevices(); // Recargar emparejados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dispositivo desconectado correctamente'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _checkBluetoothStatus() async {
    bool locationOn = await Permission.location.serviceStatus.isEnabled;
    bool bluetoothOn = await bluetooth.isBluetoothEnabled();
    bool scanGranted = await Permission.bluetoothScan.isGranted;
    bool connectGranted = await Permission.bluetoothConnect.isGranted;
    bool locationGranted = await Permission.location.isGranted;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Estado Bluetooth"),
        content: Text(
          "Bluetooth encendido: ${bluetoothOn ? '✅' : '❌'}\n"
              "Ubicación activada: ${locationOn ? '✅' : '❌'}\n"
              "Permiso BLUETOOTH_SCAN: ${scanGranted ? '✅' : '❌'}\n"
              "Permiso BLUETOOTH_CONNECT: ${connectGranted ? '✅' : '❌'}\n"
              "Permiso de ubicación: ${locationGranted ? '✅' : '❌'}",
        ),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text("Abrir ajustes"),
          ),
        ],
      ),
    );
  }

  String _manualMac = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        title: const Text("Conexión Bluetooth"),
        backgroundColor: Colors.black,
        actions: [
          if (bluetooth.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.purple),
              onPressed: disconnectDevice,
              tooltip: 'Desconectar',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: bluetooth.isConnected
                        ? Colors.green.withOpacity(0.2)
                        : moradoLumisense.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    bluetooth.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    size: 70,
                    color: bluetooth.isConnected ? Colors.green : moradoLumisense,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                connectionStatus,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ========== BOTÓN CONDICIONAL: ESCANEAR O DESCONECTAR ==========
              if (!bluetooth.isConnected) ...[
                ElevatedButton.icon(
                  onPressed: isScanning ? null : startManualScan,
                  icon: Icon(isScanning ? Icons.hourglass_empty : Icons.search),
                  label: Text(isScanning ? "Escaneando..." : "Buscar dispositivos LumiSense"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moradoLumisense,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // 🟢 BOTÓN GRANDE DE DESCONEXIÓN (visible solo cuando conectado)
                ElevatedButton.icon(
                  onPressed: disconnectDevice,
                  icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                  label: const Text("Desconectar dispositivo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Dispositivos emparejados (solo si NO está conectado)
              if (!bluetooth.isConnected && !loadingPaired && pairedDevices.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dispositivos emparejados (toca para conectar):",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pairedDevices.length,
                          itemBuilder: (context, index) {
                            final device = pairedDevices[index];
                            return Card(
                              color: const Color(0xff1E293B),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.bluetooth, color: Colors.green),
                                title: Text(
                                  device.name ?? "Sin nombre",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  device.address,
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                trailing: isConnecting
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                  onPressed: () => connectToDevice(device),
                                  child: const Text("Conectar"),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Dispositivos escaneados (solo si NO está conectado)
              if (!bluetooth.isConnected && scannedDevices.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dispositivos encontrados en escaneo:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: scannedDevices.length,
                        itemBuilder: (context, index) {
                          final device = scannedDevices[index];
                          return Card(
                            color: const Color(0xff1E293B),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(Icons.bluetooth_searching, color: moradoLumisense),
                              title: Text(
                                device.name ?? "Desconocido",
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                device.address,
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => connectToDevice(device),
                                child: const Text("Conectar"),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Mensaje si no hay nada
              if (!bluetooth.isConnected &&
                  !loadingPaired &&
                  pairedDevices.isEmpty &&
                  scannedDevices.isEmpty &&
                  !isScanning)
                Column(
                  children: [
                    const Text(
                      "No hay dispositivos LumiSense emparejados ni encontrados.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _checkBluetoothStatus,
                      icon: const Icon(Icons.info),
                      label: const Text("Verificar estado"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "O ingresa la dirección MAC manualmente:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Dirección MAC (ej: 12:34:56:78:90:AB)",
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _manualMac = value,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _manualMac.isNotEmpty
                          ? () async {
                        BluetoothDevice device = BluetoothDevice(
                          address: _manualMac,
                          name: "Manual",
                        );
                        await connectToDevice(device);
                      }
                          : null,
                      icon: const Icon(Icons.link),
                      label: const Text("Conectar por MAC"),
                      style: ElevatedButton.styleFrom(backgroundColor: moradoLumisense),
                    ),
                  ],
                ),
              if (loadingPaired) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}