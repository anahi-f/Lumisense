import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager {
  static final BluetoothManager instance = BluetoothManager._internal();
  BluetoothManager._internal();

  factory BluetoothManager() => instance;

  BluetoothConnection? _connection;
  bool isConnected = false;
  bool scanning = false;

  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);

  StreamSubscription? _inputSubscription;
  StreamSubscription? _discoverySubscription;

  // Variables de estado para persistir entre pantallas
  String? modoActivo;
  bool ledOn = false;
  Color selectedColor = Colors.blue;
  double intensity = 100.0;   // 0-100
  double speed = 20.0;        // 0-40

  // Lista de dispositivos emparejados
  List<BluetoothDevice> bondedDevices = [];

  Future<bool> requestPermissions() async {
    try {
      List<Permission> permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth,
        Permission.location,
      ];
      Map<Permission, PermissionStatus> statuses = await permissions.request();
      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        if (statuses.values.any((s) => s.isPermanentlyDenied)) {
          await openAppSettings();
        }
      }
      return allGranted;
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await FlutterBluetoothSerial.instance.isEnabled ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint("Error getting bonded devices: $e");
      return [];
    }
  }

  Future<void> cancelScan() async {
    try {
      await _discoverySubscription?.cancel();
      await FlutterBluetoothSerial.instance.cancelDiscovery();
    } catch (e) {
      debugPrint("Error cancelando discovery: $e");
    } finally {
      scanning = false;
    }
  }

  Future<void> startScan(Function(BluetoothDevice) onDeviceFound) async {
    if (isConnected || scanning) {
      debugPrint("⚠️ Ya escaneando o conectado");
      return;
    }

    debugPrint("🟡 Iniciando escaneo...");
    bool granted = await requestPermissions();
    debugPrint("🟡 Permisos concedidos: $granted");
    if (!granted) {
      debugPrint("🔴 Permisos denegados");
      return;
    }

    bool locationEnabled = await Permission.location.serviceStatus.isEnabled;
    debugPrint("🟡 Ubicación activada: $locationEnabled");
    if (!locationEnabled) {
      debugPrint("🔴 La ubicación no está activada");
      // Opcional: mostrar diálogo
    }

    bool bluetoothOn = await isBluetoothEnabled();
    debugPrint("🟡 Bluetooth encendido: $bluetoothOn");
    if (!bluetoothOn) {
      try {
        await FlutterBluetoothSerial.instance.requestEnable();
        await Future.delayed(const Duration(seconds: 2));
        bluetoothOn = await isBluetoothEnabled();
        debugPrint("🟡 Bluetooth después de requestEnable: $bluetoothOn");
      } catch (e) {
        debugPrint("🔴 Error al encender Bluetooth: $e");
      }
    }

    if (!bluetoothOn) {
      debugPrint("🔴 Bluetooth sigue apagado, no se puede escanear");
      return;
    }

    scanning = true;

    // Obtener emparejados
    try {
      bondedDevices = await getBondedDevices();
      debugPrint("📱 Dispositivos emparejados encontrados: ${bondedDevices.length}");
      for (var device in bondedDevices) {
        debugPrint("   - ${device.name} (${device.address})");
        onDeviceFound(device);
      }
    } catch (e) {
      debugPrint("🔴 Error obteniendo emparejados: $e");
    }

    // Iniciar descubrimiento
    try {
      debugPrint("🟡 Iniciando discovery...");
      _discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
            (result) {
          debugPrint("🔍 Descubierto: ${result.device.name} (${result.device.address})");
          onDeviceFound(result.device);
        },
        onError: (e) {
          debugPrint("🔴 Error en discovery: $e");
          scanning = false;
        },
        onDone: () {
          debugPrint("✅ Discovery finalizado");
          scanning = false;
        },
      );
    } catch (e) {
      debugPrint("🔴 Error iniciando discovery: $e");
      scanning = false;
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (isConnected) {
      debugPrint("YA CONECTADO");
      return;
    }

    try {
      debugPrint("Conectando a: ${device.name} (${device.address})");

      _connection = await BluetoothConnection.toAddress(device.address);

      _inputSubscription = _connection!.input!.listen((data) {
        String message = String.fromCharCodes(data).trim();
        debugPrint("📩 Recibido: $message");
        // Aquí puedes procesar respuestas si es necesario
      }, onDone: () {
        _forceDisconnect();
      });

      isConnected = true;
      connectionNotifier.value = true;

      debugPrint("✅ Conexión SPP establecida");
    } catch (e) {
      debugPrint("Error en conexión: $e");
      _forceDisconnect();
      rethrow;
    }
  }

  Future<void> send(String message) async {
    if (!isConnected || _connection == null) {
      debugPrint("❌ No conectado, no se puede enviar: $message");
      return;
    }

    try {
      final data = Uint8List.fromList((message + '\n').codeUnits);
      _connection!.output.add(data);
      await _connection!.output.allSent;
      debugPrint("📤 Enviado: $message");
    } catch (e) {
      debugPrint("❌ Error enviando: $e");
      _forceDisconnect();
    }
  }

  Future<void> disconnect() async {
    try {
      await _inputSubscription?.cancel();
      await _connection?.close();
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    } finally {
      _forceDisconnect();
    }
  }

  void _forceDisconnect() {
    isConnected = false;
    connectionNotifier.value = false;
    _connection = null;
    _inputSubscription?.cancel();
    // Al desconectar, apagar LED localmente (opcional)
    ledOn = false;
  }
}