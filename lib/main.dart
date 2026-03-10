import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: WatchDashboard()));

class WatchDashboard extends StatefulWidget {
  const WatchDashboard({super.key});
  @override
  State<WatchDashboard> createState() => _WatchDashboardState();
}

class _WatchDashboardState extends State<WatchDashboard> {
  String watchName = "Ultra 3"; // From your screenshot
  String connectionStatus = "Connected";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        title: const Text("Kelvin", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF26C6DA), // Teal color from your image
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Teal Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF26C6DA),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Connected", style: TextStyle(color: Colors.white70)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(10)),
                        child: const Text("Golden beans: ", style: TextStyle(fontSize: 12, color: Colors.white)),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Device Status Card
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.watch, color: Color(0xFF26C6DA), size: 40),
                  title: Text("$watchName | 45:52"),
                  subtitle: Text(connectionStatus),
                  trailing: const Icon(Icons.battery_full, color: Colors.grey),
                ),
              ),
            ),

            // Settings Menu List
            _buildMenuItem(Icons.settings, "Device settings", Colors.blue),
            _buildMenuItem(Icons.watch_outlined, "Dial", Colors.cyan),
            _buildMenuItem(Icons.directions_run, "Goal Steps", Colors.orange, trailing: "5000Step"),
            _buildMenuItem(Icons.color_lens, "Theme Switch", Colors.pinkAccent),
            _buildMenuItem(Icons.straighten, "Unit Switch", Colors.green),
            _buildMenuItem(Icons.security, "Background protection", Colors.blueAccent),
            _buildMenuItem(Icons.lock_person, "System authority management", Colors.redAccent),
            _buildMenuItem(Icons.info_outline, "About", Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.grey)),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () {
            // Add Bluetooth command logic here
          },
        ),
      ),
    );
  }
}

