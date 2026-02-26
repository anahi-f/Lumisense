import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import '../Bluetooth/global.dart';
import 'control_page.dart';

class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen>
    with SingleTickerProviderStateMixin {

  String connectionStatus = "Buscando dispositivo LumiSense...";
  bool isScanning = true;
  bool isConnecting = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<ble.BluetoothDevice> foundDevices = [];

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

    // Verificar si ya está conectado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bluetooth.isConnected) {
        _showAlreadyConnected();
      } else {
        _startAutoConnect();
      }
    });
  }

  void _showAlreadyConnected() {
    setState(() {
      connectionStatus = "Dispositivo ya conectado";
      isScanning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Ya estás conectado a LumiSense'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navegar automáticamente después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ControlPage()),
        );
      }
    });
  }

  Future<void> _startAutoConnect() async {
    setState(() {
      isScanning = true;
      connectionStatus = "Buscando dispositivo LumiSense...";
    });

    try {
      await bluetooth.startScan((device) {
        if (device.platformName == "LumiSense ESP32" && mounted) {
          setState(() {
            if (!foundDevices.any((d) => d.remoteId == device.remoteId)) {
              foundDevices.add(device);
            }
          });
        }
      });

      // Esperar 3 segundos para encontrar dispositivos
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      if (foundDevices.isNotEmpty) {
        _connectToDevice(foundDevices.first);
      } else {
        setState(() {
          isScanning = false;
          connectionStatus = "No se encontró LumiSense ESP32";
        });
      }
    } catch (e) {
      setState(() {
        isScanning = false;
        connectionStatus = "Error al buscar dispositivos";
      });
    }
  }

  Future<void> _connectToDevice(ble.BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
      isScanning = false;
      connectionStatus = "Conectando a LumiSense...";
    });

    try {
      await bluetooth.connect(device);

      if (!mounted) return;

      if (bluetooth.isConnected) {
        setState(() {
          connectionStatus = "¡Conectado exitosamente!";
          isConnecting = false;
        });

        // Mostrar notificación de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ LumiSense ESP32 conectado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navegar a la pantalla de control
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ControlPage()),
            );
          }
        });
      } else {
        throw Exception("No se pudo conectar");
      }
    } catch (e) {
      setState(() {
        connectionStatus = "Error al conectar";
        isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _retryScan() {
    setState(() {
      foundDevices.clear();
    });
    _startAutoConnect();
  }

  void _manualConnect() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => const ManualConnectSheet(),
    ).then((_) {
      // Al cerrar el modal, verificar si ya está conectado
      if (bluetooth.isConnected && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ControlPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icono animado
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    size: 70,
                    color: bluetooth.isConnected
                        ? Colors.green
                        : (isConnecting ? Colors.amber : Colors.blueAccent),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Texto de estado
              Text(
                connectionStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Animación de carga
              if (isScanning || isConnecting)
                Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isScanning ? "Escaneando..." : "Estableciendo conexión...",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              // Botones de acción
              if (!isScanning && !isConnecting && !bluetooth.isConnected)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retryScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Reintentar conexión automática",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton.icon(
                      onPressed: _manualConnect,
                      icon: const Icon(Icons.list),
                      label: const Text(
                        "Ver dispositivos disponibles",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

              if (bluetooth.isConnected)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ControlPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    "Continuar al control",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal para conexión manual
class ManualConnectSheet extends StatefulWidget {
  const ManualConnectSheet({super.key});

  @override
  State<ManualConnectSheet> createState() => _ManualConnectSheetState();
}

class _ManualConnectSheetState extends State<ManualConnectSheet> {
  List<ble.BluetoothDevice> devices = [];
  bool scanning = true;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  Future<void> startScan() async {
    setState(() => scanning = true);

    await bluetooth.startScan((device) {
      if (device.platformName == "LumiSense ESP32" && mounted) {
        setState(() {
          if (!devices.any((d) => d.remoteId == device.remoteId)) {
            devices.add(device);
          }
        });
      }
    });

    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      setState(() => scanning = false);
    }
  }

  Future<void> connectToDevice(ble.BluetoothDevice device) async {
    Navigator.pop(context); // Cerrar el modal

    try {
      await bluetooth.connect(device);

      if (mounted && bluetooth.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ LumiSense ESP32 conectado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error al conectar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No se encontró LumiSense ESP32",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        devices.clear();
                        startScan();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Buscar nuevamente"),
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
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.memory,
                      color: Colors.cyan,
                    ),
                    title: Text(
                      device.platformName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      device.remoteId.str.substring(0, 17) + "...",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => connectToDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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