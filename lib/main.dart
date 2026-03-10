@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    // Bottom Navigation Bar matching your screenshot
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF26C6DA),
      unselectedItemColor: Colors.grey,
      currentIndex: 4, // "Me" tab selected
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: "Health"),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Data"),
        BottomNavigationBarItem(icon: Icon(Icons.Games), label: "GAME"),
        BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: "Exercise"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Me"),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Teal Header
              Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFF26C6DA),
                padding: const EdgeInsets.only(top: 60, left: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Kelvin", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(20)),
                          child: const Text("Golden beans:", style: TextStyle(color: Colors.white, fontSize: 12)),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Icon(Icons.link, color: Colors.white70, size: 18),
                        Text(" Connected", style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  ],
                ),
              ),
              // 2. Profile Image (Top Right)
              Positioned(
                right: 20,
                top: 70,
                child: CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.3), child: const Icon(Icons.person, size: 60, color: Colors.white)),
              ),
              // 3. Floating Watch Card
              Positioned(
                bottom: -40,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: Color(0xFFB2EBF2), child: Icon(Icons.watch, color: Color(0xFF00ACC1))),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ultra 3 | 45:52", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Connected", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.battery_full, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          
          // 4. "Earn Golden Beans" Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network('https://via.placeholder.com/400x120', fit: BoxFit.cover), // Replace with your asset later
            ),
          ),

          // 5. Settings List
          _buildHryItem(Icons.settings, "Device settings", Colors.blueAccent),
          _buildHryItem(Icons.watch, "Dial", Colors.cyan),
          _buildHryItem(Icons.directions_run, "Goal Steps", Colors.orange, trailing: "5000Step"),
          _buildHryItem(Icons.checkroom, "Theme Switch", Colors.pinkAccent),
          _buildHryItem(Icons.straighten, "Unit Switch", Colors.green),
          _buildHryItem(Icons.security, "Background protection", Colors.blue),
          _buildHryItem(Icons.lock_person, "System authority management", Colors.redAccent),
          _buildHryItem(Icons.info, "About", Colors.purpleAccent),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _buildHryItem(IconData icon, String title, Color color, {String? trailing}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
    title: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.grey)),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    ),
    onTap: () {},
  );
}
