import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart'; // Ready for your Data screen
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ultra 3 Companion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const HomeScreen(),
      );
}

// --- BLE Manager ---
class BleManager {
  static BluetoothDevice? connectedDevice;
  static BluetoothCharacteristic? writeChar;

  // Standard UUIDs for HryFine/Ultra 3 style watches
  static final Guid serviceUuid = Guid("0000ff00-0000-1000-8000-00805f9b34fb");
  static final Guid writeUuid = Guid("0000ff02-0000-1000-8000-00805f9b34fb");
}

// --- Main Navigation Controller ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 4; // Default to 'Me' screen for setup
  bool _autoMirroring = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Handling modern Android 13+ and legacy permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.photos,
      Permission.notification,
    ].request();
    
    print("Permissions status: $statuses");
  }

  // Notification Mirroring Logic
  Future<void> _toggleAutoMirroring(bool value) async {
    setState(() => _autoMirroring = value);
    if (value) {
      final hasPermission = await NotificationListenerService.isPermissionGranted();
      if (!hasPermission) {
        await NotificationListenerService.requestPermission();
      }

      NotificationListenerService.notificationsStream.listen((event) {
        if (BleManager.writeChar == null) return;
        
        final isCall = event.packageName?.contains("phone") == true ||
            (event.title?.toLowerCase().contains("call") ?? false);

        _sendToWatch(
          title: event.title ?? "Notification",
          body: event.text ?? "",
          isCall: isCall,
          package: event.packageName ?? "app",
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification Mirroring Enabled")),
      );
    }
  }

  Future<void> _sendToWatch({
    required String title,
    required String body,
    required bool isCall,
    required String package,
  }) async {
    try {
      final command = isCall
          ? [0x02, 0x00, 0x00, ...title.codeUnits, 0x00, ...body.codeUnits]
          : [0x01, 0x00, 0x00, ..."$package:$title".codeUnits, 0x00, ...body.codeUnits];
      
      // Update length byte (standard protocol for these watches)
      if (command.length > 2) command[1] = command.length - 3;

      await BleManager.writeChar!.write(Uint8List.fromList(command), withoutResponse: false);
    } catch (e) {
      print("Send error: $e");
    }
  }

  // Bluetooth Connection Logic
  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        final name = r.device.platformName;
        if (name.contains("Ultra 3") || name.contains("HryFine")) {
          FlutterBluePlus.stopScan();
          try {
            await r.device.connect();
            BleManager.connectedDevice = r.device;
            
            // Request higher MTU for data-heavy transfers (notifications/images)
            await r.device.requestMtu(223); 
            
            await _discoverServices();
            setState(() => _isConnecting = false);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$name Connected!")),
            );
          } catch (e) {
            print("Connection error: $e");
            setState(() => _isConnecting = false);
          }
          break;
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    if (BleManager.connectedDevice == null) return;
    final services = await BleManager.connectedDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid == BleManager.serviceUuid) {
        for (var char in service.characteristics) {
          if (char.uuid == BleManager.writeUuid) {
            BleManager.writeChar = char;
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const Center(child: Text("Health Data")),
            const Center(child: Text("Analytics Chart")),
            const Center(child: Text("Games")),
            const Center(child: Text("Exercise Tracking")),
            MeScreen(
              onConnect: _connect,
              isConnecting: _isConnecting,
              autoMirroring: _autoMirroring,
              onToggleMirroring: _toggleAutoMirroring,
              isConnected: BleManager.connectedDevice != null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: "Health"),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: "Data"),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "Game"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: "Exercise"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
    );
  }
}

// --- Me Screen (Settings & Connection) ---
class MeScreen extends StatelessWidget {
  final Future<void> Function() onConnect;
  final bool isConnecting;
  final bool autoMirroring;
  final bool isConnected;
  final Future<void> Function(bool) onToggleMirroring;

  const MeScreen({
    super.key,
    required this.onConnect,
    required this.isConnecting,
    required this.autoMirroring,
    required this.isConnected,
    required this.onToggleMirroring,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.watch, color: isConnected ? Colors.green : Colors.grey),
            title: Text(isConnected ? "Watch Connected" : "No Watch Found"),
            subtitle: Text(isConnecting ? "Scanning..." : "Status check"),
            trailing: isConnecting 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: isConnected ? null : onConnect,
                  child: const Text("Connect"),
                ),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SwitchListTile(
          title: const Text("Auto Notification Mirroring"),
          subtitle: const Text("Forward phone alerts to watch"),
          value: autoMirroring,
          onChanged: isConnected ? onToggleMirroring : null,
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text("Custom Watch Face"),
          subtitle: const Text("Upload image to watch"),
          onTap: () {
            // Logic for image_picker goes here
          },
        ),
      ],
    );
  }
}
