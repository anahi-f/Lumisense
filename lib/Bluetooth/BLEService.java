import 'bluetooth_service.dart';

BLEService bluetooth = BLEService();

  BluetoothDevice? device;
  BluetoothCharacteristic? writeCharacteristic;

  /// ESCANEAR
  Future<void> startScan(Function(BluetoothDevice) onDeviceFound) async {

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.platformName == "ESP32") {
          onDeviceFound(r.device);
        }
      }
    });
  }

  /// CONECTAR
  Future<void> connect(BluetoothDevice newDevice) async {

    device = newDevice;

    await device!.connect();

    List<BluetoothService> services =
        await device!.discoverServices();

    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.properties.write) {
          writeCharacteristic = c;
        }
      }
    }
  }

  /// ENVIAR
  Future<void> sendData(List<int> data) async {
    if (writeCharacteristic != null) {
      await writeCharacteristic!.write(data, withoutResponse: true);
    }
  }
}