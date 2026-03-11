import 'package:flutter/material.dart';

class HealthDataPage extends StatelessWidget {
  const HealthDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Data"),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          "Health tracking stats will appear here.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
