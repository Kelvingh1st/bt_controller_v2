import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OrbitalController(),
    ));

class OrbitalController extends StatefulWidget {
  const OrbitalController({super.key});

  @override
  State<OrbitalController> createState() => _OrbitalControllerState();
}

class _OrbitalControllerState extends State<OrbitalController> {
  String status = "Ready";

  void sendCommand(String cmd) {
    setState(() => status = "Sending: $cmd");
    print("Action: $cmd");
    // Bluetooth transmit logic will be added here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17), // Space theme
      appBar: AppBar(
        title: const Text("My watch app"),
        backgroundColor: Colors.indigo.withOpacity(0.3),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("STATUS: $status", 
                 style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return SizedBox(
      width: 280,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: [
          Container(),
          _btn(Icons.arrow_upward, "F"),
          Container(),
          _btn(Icons.arrow_back, "L"),
          _btn(Icons.stop, "S", color: Colors.redAccent),
          _btn(Icons.arrow_forward, "R"),
          Container(),
          _btn(Icons.arrow_downward, "B"),
          Container(),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String cmd, {Color color = Colors.cyanAccent}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => sendCommand(cmd),
      child: Icon(icon, color: color, size: 35),
    );
  }
}

