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

  // 🔹 FILTRO: solo dispositivos que se llamen exactamente "LumiSense ESP32"
  bool _isOurDevice(BluetoothDevice device) {
    final name = device.name ?? "";
    return name == "LumiSense ESP32" || name.contains("LumiSense ESP32");
  }

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

  // ========== Cargar dispositivos emparejados (solo LumiSense) ==========
  Future<void> _loadPairedDevices() async {
    setState(() {
      loadingPaired = true;
      connectionStatus = "Obteniendo dispositivos emparejados...";
    });
    try {
      final devices = await bluetooth.getBondedDevices();
      final List<BluetoothDevice> filtered = [];
      for (var device in devices) {
        if (_isOurDevice(device)) {
          filtered.add(device);
          debugPrint("✅ Emparejado válido: ${device.name} (${device.address})");
        } else {
          debugPrint("⛔ Emparejado ignorado: ${device.name}");
        }
      }
      setState(() {
        pairedDevices = filtered;
        if (pairedDevices.isNotEmpty) {
          connectionStatus = "Selecciona tu dispositivo LumiSense ESP32";
        } else {
          connectionStatus = "No hay LumiSense ESP32 emparejado. Escanea o conecta manualmente.";
        }
      });
    } catch (e) {
      setState(() {
        connectionStatus = "Error al cargar emparejados: $e";
      });
    } finally {
      setState(() => loadingPaired = false);
    }
  }

  // ========== Escaneo manual (solo LumiSense) ==========
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
        if (_isOurDevice(device)) {
          if (mounted) {
            setState(() {
              if (!scannedDevices.any((d) => d.address == device.address)) {
                scannedDevices.add(device);
                debugPrint("📱 Escaneado (válido): ${device.name} (${device.address})");
              }
            });
          }
        } else {
          debugPrint("⛔ Escaneado ignorado: ${device.name}");
        }
      });

      _scanTimer = Timer(const Duration(seconds: 10), () async {
        if (mounted) {
          await bluetooth.cancelScan();
          setState(() {
            isScanning = false;
            if (scannedDevices.isEmpty && pairedDevices.isEmpty) {
              connectionStatus = "❌ No se encontró ningún dispositivo LumiSense ESP32. Verifica que esté encendido y visible.";
            } else if (scannedDevices.isEmpty && pairedDevices.isNotEmpty) {
              connectionStatus = "No se encontraron nuevos, pero tienes LumiSense ESP32 emparejado abajo.";
            } else {
              connectionStatus = "Selecciona LumiSense ESP32 para conectar";
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
          SnackBar(content: Text('✓ Conectado a ${device.name ?? device.address}'), backgroundColor: Colors.green),
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

  Future<void> disconnectDevice() async {
    await bluetooth.disconnect();
    setState(() {
      scannedDevices.clear();
      pairedDevices.clear();
      isScanning = false;
      isConnecting = false;
      connectionStatus = "Desconectado. Busca o selecciona tu dispositivo.";
    });
    await _loadPairedDevices();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dispositivo desconectado correctamente'), backgroundColor: Colors.orange),
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
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
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
              if (!bluetooth.isConnected) ...[
                ElevatedButton.icon(
                  onPressed: isScanning ? null : startManualScan,
                  icon: Icon(isScanning ? Icons.hourglass_empty : Icons.search),
                  label: Text(isScanning ? "Escaneando..." : "Buscar LumiSense ESP32"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moradoLumisense,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Dispositivos emparejados
              if (!bluetooth.isConnected && !loadingPaired && pairedDevices.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Dispositivos emparejados:", style: TextStyle(color: Colors.white70)),
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
                                  device.name ?? "LumiSense ESP32",
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
              // Dispositivos escaneados
              if (!bluetooth.isConnected && scannedDevices.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Dispositivos encontrados:", style: TextStyle(color: Colors.white70)),
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
                                device.name ?? "LumiSense ESP32",
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
              // Mensaje cuando no hay nada
              if (!bluetooth.isConnected &&
                  !loadingPaired &&
                  pairedDevices.isEmpty &&
                  scannedDevices.isEmpty &&
                  !isScanning)
                Column(
                  children: [
                    const Text("No hay dispositivos LumiSense ESP32 emparejados ni encontrados.", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _checkBluetoothStatus,
                      icon: const Icon(Icons.info),
                      label: const Text("Verificar estado"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    const SizedBox(height: 20),
                    const Text("O ingresa la dirección MAC manualmente:", style: TextStyle(color: Colors.white70)),
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
                          name: "LumiSense ESP32",
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