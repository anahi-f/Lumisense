import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothManager {
  static final BluetoothManager instance = BluetoothManager._internal();
  BluetoothManager._internal();

  factory BluetoothManager() => instance;

  BluetoothConnection? _connection;
  bool isConnected = false;
  bool scanning = false;
  bool _reconnecting = false;
  // Timer? _keepAliveTimer;  // ✅ ELIMINADO: ya no se usa
  String? _lastConnectedMac;

  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);

  StreamSubscription? _inputSubscription;
  StreamSubscription? _discoverySubscription;

  // Variables de estado persistentes
  String? modoActivo;
  bool ledOn = false;
  Color selectedColor = Colors.blue;
  double intensity = 100.0;
  double speed = 20.0;

  List<BluetoothDevice> bondedDevices = [];

  // ========== PERMISOS Y ESTADO ==========
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

  // ========== ESCANEO ==========
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
    if (!granted) return;

    bool locationEnabled = await Permission.location.serviceStatus.isEnabled;
    debugPrint("🟡 Ubicación activada: $locationEnabled");

    bool bluetoothOn = await isBluetoothEnabled();
    debugPrint("🟡 Bluetooth encendido: $bluetoothOn");
    if (!bluetoothOn) {
      try {
        await FlutterBluetoothSerial.instance.requestEnable();
        await Future.delayed(const Duration(seconds: 2));
        bluetoothOn = await isBluetoothEnabled();
      } catch (e) {}
    }
    if (!bluetoothOn) return;

    scanning = true;

    try {
      bondedDevices = await getBondedDevices();
      for (var device in bondedDevices) {
        onDeviceFound(device);
      }
    } catch (e) {}

    try {
      _discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
            (result) {
          onDeviceFound(result.device);
        },
        onError: (e) {
          scanning = false;
        },
        onDone: () {
          scanning = false;
        },
      );
    } catch (e) {
      scanning = false;
    }
  }

  // ========== CONEXIÓN Y RECONEXIÓN ==========
  Future<void> _saveLastDeviceMac(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_bluetooth_mac', mac);
    _lastConnectedMac = mac;
  }

  Future<String?> getLastDeviceMac() async {
    if (_lastConnectedMac != null) return _lastConnectedMac;
    final prefs = await SharedPreferences.getInstance();
    _lastConnectedMac = prefs.getString('last_bluetooth_mac');
    return _lastConnectedMac;
  }

  Future<void> attemptReconnection() async {
    if (_reconnecting || isConnected) return;
    _reconnecting = true;
    debugPrint("🔄 Intentando reconexión automática...");
    String? mac = await getLastDeviceMac();
    if (mac == null) {
      debugPrint("⚠️ No hay MAC guardada para reconectar");
      _reconnecting = false;
      return;
    }
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!isConnected) {
        debugPrint("🔄 Reconectando a $mac");
        await connectToMac(mac);
      }
    } catch (e) {
      debugPrint("❌ Error en reconexión: $e");
    } finally {
      _reconnecting = false;
    }
  }

  Future<bool> connectToMac(String mac) async {
    if (isConnected) return true;
    try {
      BluetoothDevice device = BluetoothDevice(address: mac);
      await connect(device);
      return isConnected;
    } catch (e) {
      debugPrint("❌ Error conectando a MAC $mac: $e");
      return false;
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
      }, onDone: () {
        debugPrint("🔌 Conexión cerrada por el dispositivo remoto");
        _forceDisconnect();
        attemptReconnection();
      }, onError: (e) {
        debugPrint("❌ Error en la conexión: $e");
        _forceDisconnect();
        attemptReconnection();
      });

      isConnected = true;
      connectionNotifier.value = true;
      await _saveLastDeviceMac(device.address);
      // _startKeepAlive();  // ✅ ELIMINADO: ya no se envía KEEPALIVE
      debugPrint("✅ Conexión SPP establecida");
    } catch (e) {
      debugPrint("Error en conexión: $e");
      _forceDisconnect();
      rethrow;
    }
  }

  // ❌ ELIMINADO: método _startKeepAlive() para no enviar KEEPALIVE

  // ========== ENVÍO DE DATOS ==========
  Future<void> send(String message) async {
    if (!isConnected || _connection == null) {
      debugPrint("❌ No conectado, no se puede enviar: $message");
      attemptReconnection();
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
      attemptReconnection();
    }
  }

  // ========== DESCONEXIÓN ==========
  Future<void> disconnect() async {
    // _keepAliveTimer?.cancel(); // ❌ Ya no existe
    // _keepAliveTimer = null;
    try {
      if (_connection != null) {
        if (ledOn) {
          await send("OFF");
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await _inputSubscription?.cancel();
        await _connection?.close();
      }
    } catch (e) {
      debugPrint("Error durante desconexión: $e");
    } finally {
      _forceDisconnect();
      modoActivo = null;
      ledOn = false;
      selectedColor = Colors.blue;
      intensity = 100.0;
      speed = 20.0;
    }
  }

  void _forceDisconnect() {
    isConnected = false;
    connectionNotifier.value = false;
    _connection = null;
    _inputSubscription?.cancel();
    ledOn = false;
    // _keepAliveTimer?.cancel(); // ❌ Ya no existe
    // _keepAliveTimer = null;
  }
}