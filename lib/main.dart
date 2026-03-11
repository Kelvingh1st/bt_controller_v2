import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'health_data.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WatchDashboard(),
  ));
}

class WatchDashboard extends StatefulWidget {
  const WatchDashboard({super.key});

  @override
  State<WatchDashboard> createState() => _WatchDashboardState();
}

class _WatchDashboardState extends State<WatchDashboard> {
  String connectionStatus = "Disconnected";
  int watchBatteryLevel = 0;

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
  }

  // --- 1. Bluetooth Connection Logic ---
  void _getBatteryLevel() async {
    // Start scanning for 4 seconds
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    // Listen to results
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        // Use platformName to avoid deprecation warnings
        if (r.device.platformName == "Ultra 3") {
          await FlutterBluePlus.stopScan();
          try {
            // This is Line 38 - No 'license' parameter needed here!
            await r.device.connect();
            setState(() {
              connectionStatus = "Connected";
            });

            List<BluetoothService> services = await r.device.discoverServices();
            for (BluetoothService service in services) {
              // Battery Service UUID is 180F
              if (service.uuid.toString().toUpperCase().contains("180F")) {
                for (BluetoothCharacteristic c in service.characteristics) {
                  List<int> value = await c.read();
                  if (value.isNotEmpty) {
                    setState(() {
                      watchBatteryLevel = value[0];
                    });
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Connection error: $e");
            setState(() => connectionStatus = "Error");
          }
        }
      }
    });
  }

  // --- 2. UI Action Dialogs ---
  void showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Available!"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Version: v1.0.3", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("• Improved Sync\n• Battery Optimization"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Later")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
            child: const Text("Update Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showDeviceScanner(BuildContext context) {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Scanner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const LinearProgressIndicator(color: Color(0xFF26C6DA)),
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final device = results[index].device;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.platformName.isEmpty ? "Unknown" : device.platformName),
                        onTap: () async {
                          await FlutterBluePlus.stopScan();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. UI Helpers & Build ---
  Widget buildMenuItem(IconData icon, String title, {Color color = Colors.grey, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ultra Watch"),
        backgroundColor: const Color(0xFF26C6DA),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.watch)),
                title: const Text("Ultra 3"),
                subtitle: Text(connectionStatus),
                trailing: Text("$watchBatteryLevel%", style: const TextStyle(fontSize: 18)),
              ),
            ),
            const Divider(),
            buildMenuItem(Icons.bluetooth_searching, "Scan Devices", onTap: () => showDeviceScanner(context)),
            buildMenuItem(Icons.system_update, "Software Update", onTap: () => showUpdateDialog(context)),
            buildMenuItem(Icons.favorite, "Health Data", color: Colors.red, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthDataPage()));
            }),
            buildMenuItem(Icons.info, "About", color: Colors.blue, onTap: () {
              showAboutDialog(context: context, applicationName: "Ultra Controller");
            }),
          ],
        ),
      ),
    );
  }
}
