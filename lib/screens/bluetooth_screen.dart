// ============================================
// bluetooth_screen.dart (COMPLETO)
// ============================================

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

  String connectionStatus = "Buscar dispositivo...";
  bool isScanning = false;
  bool isConnecting = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<BluetoothDevice> foundDevices = [];
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
      if (bluetooth.isConnected) _navigateToControl();
    });
  }

  void _navigateToControl() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ControlPage()),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    bluetooth.cancelScan();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> startManualScan() async {
    _scanTimer?.cancel();
    await bluetooth.cancelScan();

    setState(() {
      isScanning = true;
      foundDevices.clear();
      connectionStatus = "Buscando dispositivos...";
    });

    try {
      await bluetooth.startScan((device) {
        // FILTRO: mostrar dispositivos que contengan "LumiSense" o "ESP32"
        final deviceName = device.name ?? "";
        if (deviceName.contains("LumiSense") || deviceName.contains("ESP32")) {
          if (mounted) {
            setState(() {
              if (!foundDevices.any((d) => d.address == device.address)) {
                foundDevices.add(device);
                debugPrint("📱 Añadido: ${device.name} (${device.address})");
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
            connectionStatus = foundDevices.isEmpty
                ? "No se encontraron dispositivos LumiSense"
                : "Selecciona un dispositivo";
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
      connectionStatus = "Conectando a ${device.name ?? '...'}";
    });

    try {
      await bluetooth.connect(device);
      if (mounted && bluetooth.isConnected) {
        setState(() {
          connectionStatus = "¡Conectado!";
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Conectado a ${device.name}'), backgroundColor: Colors.green),
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
    setState(() => foundDevices.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dispositivo desconectado'), backgroundColor: Colors.orange),
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
              icon: const Icon(Icons.bluetooth_connected, color: Colors.green),
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
                  label: Text(isScanning ? "Escaneando..." : "Buscar dispositivos"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moradoLumisense,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (foundDevices.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Dispositivos:", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: foundDevices.length,
                          itemBuilder: (context, index) {
                            final device = foundDevices[index];
                            bool isBonded = bluetooth.bondedDevices.any((d) => d.address == device.address);
                            return Card(
                              color: const Color(0xff1E293B),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
                                  color: isBonded ? Colors.green : moradoLumisense,
                                ),
                                title: Text(
                                  device.name ?? "Desconocido",
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
              if (foundDevices.isEmpty && !isScanning)
                Column(
                  children: [
                    const Text("¿No encuentras tu dispositivo LumiSense?", style: TextStyle(color: Colors.white70)),
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
                        labelText: "Dirección MAC",
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
            ],
          ),
        ),
      ),
    );
  }
}