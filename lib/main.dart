import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'health_data.dart'; // <--- Added the import here

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
  
  // 1. The "Software Update" Dialog Tool
  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Available!"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Version: v1.0.3 (New)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 10),
            Text("• Improved Bluetooth stability\n• New Watch Face support\n• Fixed vibration sync bug"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Later")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
            onPressed: () => Navigator.pop(context), 
            child: const Text("Update Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. The Bluetooth Scanner Tool
  void _showDeviceScanner() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Searching for Ultra 3...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const LinearProgressIndicator(color: Color(0xFF26C6DA)),
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                builder: (c, snapshot) {
                  final results = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final device = results[index].device;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.platformName.isEmpty ? "Unknown" : device.platformName),
                        subtitle: Text(device.remoteId.toString()),
                        onTap: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF26C6DA),
        currentIndex: 4, // Highlights the "Me" tab
        onTap: (index) {
          // If the "Data" tab (index 1) is tapped, go to the Health Data Page
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthDataPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: "Health"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Data"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: "GAME"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: "Exercise"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: const Color(0xFF26C6DA),
                  padding: const EdgeInsets.only(top: 60, left: 25),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kelvin", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      Row(children: [Icon(Icons.link, color: Colors.white70, size: 18), Text(" Connected", style: TextStyle(color: Colors.white70))]),
                    ],
                  ),
                ),
                const Positioned(
                  right: 20, top: 60,
                  child: CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 45, color: Colors.white)),
                ),
                Positioned(
                  bottom: -30, left: 20, right: 20,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: const ListTile(
                      leading: CircleAvatar(backgroundColor: Color(0xFFE0F7FA), child: Icon(Icons.watch, color: Color(0xFF26C6DA))),
                      title: Text("Ultra 3 | 45:52", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Connected"),
                      trailing: Icon(Icons.battery_full, color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            _buildHryItem(Icons.settings, "Device settings", Colors.blueAccent, onTap: _showDeviceScanner),
            _buildHryItem(Icons.palette, "Dial", Colors.cyan),
            _buildHryItem(Icons.system_update, "Software Update", Colors.orangeAccent, onTap: () => _showUpdateDialog(context)),
            _buildHryItem(Icons.directions_run, "Goal Steps", Colors.orange, trailing: "5000Step"),
            _buildHryItem(Icons.checkroom, "Theme Switch", Colors.pinkAccent),
            _buildHryItem(Icons.security, "Background protection", Colors.blue),
            _buildHryItem(Icons.info, "About", Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildHryItem(IconData icon, String title, Color color, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

