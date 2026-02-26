import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';

class BLEManager {
  static final BLEManager instance = BLEManager._internal();
  BLEManager._internal();

  factory BLEManager() => instance;

  ble.BluetoothDevice? device;
  ble.BluetoothCharacteristic? writeCharacteristic;

  bool isConnected = false;
  bool scanning = false;

  final String targetName = "LumiSense ESP32";

  /// ================= PERMISOS
  Future<bool> requestPermissions() async {
    try {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      final location = await Permission.locationWhenInUse.request();

      return scan.isGranted && connect.isGranted && location.isGranted;
    } catch (e) {
      print("Error requesting permissions: $e");
      return false;
    }
  }

  /// ================= VERIFICAR BLUETOOTH
  Future<bool> isBluetoothEnabled() async {
    try {
      var state = await ble.FlutterBluePlus.adapterState.first;
      return state == ble.BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// ================= ESCANEAR
  Future<void> startScan(Function(ble.BluetoothDevice) onDeviceFound) async {
    if (isConnected || scanning) return;

    bool granted = await requestPermissions();
    if (!granted) return;

    scanning = true;

    try {
      await ble.FlutterBluePlus.stopScan();

      // Escuchar resultados
      ble.FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          if (r.device.platformName == targetName) {
            onDeviceFound(r.device);
          }
        }
      });

      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
      );

    } catch (e) {
      print("Error scanning: $e");
    } finally {
      scanning = false;
    }
  }

  /// ================= CONECTAR - CORREGIDO
  Future<void> connect(ble.BluetoothDevice newDevice) async {
    if (isConnected) {
      print("YA CONECTADO");
      return;
    }

    try {
      await ble.FlutterBluePlus.stopScan();

      device = newDevice;
      print("Conectando a: ${device!.platformName}");

      // CONFIGURACIÓN CORRECTA: Escuchar cambios de conexión
      device!.connectionState.listen((state) {
        print("Estado conexión: $state");

        if (state == ble.BluetoothConnectionState.connected) {
          isConnected = true;
          print("✅ ESP32 conectado");

          // IMPORTANTE: Solicitar MTU más grande para conexión estable
          device!.requestMtu(256);

        } else if (state == ble.BluetoothConnectionState.disconnected) {
          isConnected = false;
          writeCharacteristic = null;
          print("❌ ESP32 desconectado");
        }
      });

      // Conectar con timeout más largo
      await device!.connect(
        timeout: const Duration(seconds: 20), // Aumentado
      );

      // Esperar a que la conexión se estabilice
      await Future.delayed(const Duration(seconds: 1));

      // Descubrir servicios
      print("Descubriendo servicios...");
      List<ble.BluetoothService> services = await device!.discoverServices();
      print("Servicios encontrados: ${services.length}");

      // Buscar característica de escritura
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeCharacteristic = c;
            print("✅ Característica de escritura encontrada");

            // IMPORTANTE: Configurar notificaciones si es necesario
            try {
              await c.setNotifyValue(true);
            } catch (e) {
              // Ignorar si no soporta notificaciones
            }

            break;
          }
        }
        if (writeCharacteristic != null) break;
      }

      print("✅ Conexión completada");

    } catch (e) {
      print("Error en conexión: $e");
      isConnected = false;
      rethrow;
    }
  }

  /// ================= ENVIAR
  Future<void> send(String message) async {
    if (!isConnected || writeCharacteristic == null) {
      print("No conectado");
      return;
    }

    try {
      await writeCharacteristic!.write(
        message.codeUnits,
        withoutResponse: true,
      );
      print("📤 Enviado: $message");
    } catch (e) {
      print("Error enviando: $e");
    }
  }

  /// ================= DESCONECTAR
  Future<void> disconnect() async {
    try {
      await device?.disconnect();
    } catch (e) {
      print("Error disconnecting: $e");
    } finally {
      device = null;
      writeCharacteristic = null;
      isConnected = false;
    }
  }
}