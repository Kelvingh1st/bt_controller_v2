import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'My Watch App',
        theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
        home: const HomeScreen(),
      );
}

// BLE Manager
class BleManager {
  static BluetoothDevice? connectedDevice;
  static BluetoothCharacteristic? writeChar;

  static final Guid serviceUuid =
      Guid("0000ff00-0000-1000-8000-00805f9b34fb");
  static final Guid writeUuid =
      Guid("0000ff02-0000-1000-8000-00805f9b34fb");
}

// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2;
  bool _autoMirroring = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.photos,
      Permission.notification
    ].request();
  }

  Future<void> _toggleAutoMirroring(bool value) async {
    setState(() => _autoMirroring = value);
    if (value) {
      final has = await NotificationListenerService.isPermissionGranted();
      if (!has) await NotificationListenerService.requestPermission();

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
        const SnackBar(content: Text("Auto mirroring ON")),
      );
    }
  }

  Future<void> _sendToWatch({
    required String title,
    required String body,
    required bool isCall,
    required String package,
  }) async {
    final command = isCall
        ? [0x02, 0x00, 0x00, ...title.codeUnits, 0x00, ...body.codeUnits]
        : [
            0x01,
            0x00,
            0x00,
            ..."$package:$title".codeUnits,
            0x00,
            ...body.codeUnits
          ];
    command[1] = command.length - 3;
    await BleManager.writeChar!.write(Uint8List.fromList(command));
  }

  Future<void> _connect() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.platformName.contains("Ultra 3") ||
            r.device.platformName.contains("HryFine")) {
          await r.device.connect();
          BleManager.connectedDevice = r.device;
          await _discoverServices();
          setState(() {});
          FlutterBluePlus.stopScan();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ultra 3 Connected!")),
          );
          break;
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    final services = await BleManager.connectedDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid == BleManager.serviceUuid) {
        for (var char in service.characteristics) {
          if (char.uuid == BleManager.writeUuid) {
            BleManager.writeChar = char;
            print("Ultra 3 write characteristic ready!");
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const HealthScreen(),
        const DataScreen(),
        const GameScreen(),
        const ExerciseScreen(),
        MeScreen(
          onConnect: _connect,
          autoMirroring: _autoMirroring,
          onToggleMirroring: _toggleAutoMirroring,
        ),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety), label: "Health"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart), label: "Data"),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "GAME"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_run), label: "Exercise"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
    );
  }
}

// Health Screen
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            const Text("Health",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text("Kumasi 23~36℃")
          ]),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
                color: Colors.teal, borderRadius: BorderRadius.circular(20)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                      value: 16 / 5000,
                      strokeWidth: 12,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white)),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.directions_walk,
                      size: 40, color: Colors.white),
                  Text("16",
                      style: TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text("Steps", style: TextStyle(color: Colors.white70))
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _smallCard("Calories", "0.38", Icons.local_fire_department,
                Colors.red),
            const SizedBox(width: 12),
            _smallCard("Distance", "0.01km", Icons.location_on, Colors.blue)
          ]),
          const SizedBox(height: 12),
          _smallCard("Goal", "0%", Icons.flag, Colors.orange),
          const SizedBox(height: 30),
          _metricRow(Icons.fitness_center, "-- km", "Exercise"),
          _metricRow(Icons.monitor_heart, "86 Times/min", "Heart rate",
              date: "03-11"),
          _metricRow(Icons.nightlight_round, "0h0m", "Sleep"),
        ],
      ),
    );
  }

  static Widget _smallCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Row(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold))
          ])
        ]),
      ),
    );
  }

  static Widget _metricRow(IconData icon, String value, String label,
      {String? date}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.teal),
        title: Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(label),
        trailing: date != null
            ? Text(date)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

// Data Screen
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Health data",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

