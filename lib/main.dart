import 'dart:typed_data';
import 'dart:io';
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

  static final Guid serviceUuid = Guid("0000ff00-0000-1000-8000-00805f9b34fb");
  static final Guid writeUuid = Guid("0000ff02-0000-1000-8000-00805f9b34fb");
}

// --- Main Controller ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 4; // Start on 'Me' screen for setup
  bool _autoMirroring = false;
  bool _isConnecting = false;
  
  // Image Upload State
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.photos,
      Permission.notification,
    ].request();
  }

  // --- Notification Logic ---
  Future<void> _toggleAutoMirroring(bool value) async {
    setState(() => _autoMirroring = value);
    if (value) {
      final has = await NotificationListenerService.isPermissionGranted();
      if (!has) await NotificationListenerService.requestPermission();

      NotificationListenerService.notificationsStream.listen((event) {
        if (BleManager.writeChar == null) return;
        final isCall = event.packageName?.contains("phone") == true;

        _sendToWatch(
          title: event.title ?? "Notification",
          body: event.content ?? "", // Fixed from analysis
          isCall: isCall,
          package: event.packageName ?? "app",
        );
      });
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
      
      if (command.length > 2) command[1] = command.length - 3;
      await BleManager.writeChar?.write(Uint8List.fromList(command), withoutResponse: false);
    } catch (e) {
      debugPrint("Write error: $e");
    }
  }

  // --- Bluetooth Logic ---
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
            await r.device.requestMtu(223); // Important for data chunks
            await _discoverServices();
            setState(() => _isConnecting = false);
          } catch (e) {
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
          }
        }
      }
    }
  }

  // --- Image Upload Logic (Chunked) ---
  Future<void> _pickAndUploadWatchFace() async {
    if (BleManager.writeChar == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connect watch first!")));
      return;
    }

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() { _isUploading = true; _uploadProgress = 0.0; });

      File file = File(pickedFile.path);
      Uint8List bytes = await file.readAsBytes();

      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        img.Image resized = img.copyResize(originalImage, width: 240, height: 240);
        List<int> jpgData = img.encodeJpg(resized, quality: 80);

        await _sendImageInChunks(jpgData);
      }
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendImageInChunks(List<int> data) async {
    const int chunkSize = 200;
    int totalBytes = data.length;

    // Start Command
    final startCmd = [0x03, ..._int32ToBytes(totalBytes)];
    await BleManager.writeChar!.write(Uint8List.fromList(startCmd));

    for (int i = 0; i < totalBytes; i += chunkSize) {
      int end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
      List<int> chunk = data.sublist(i, end);

      try {
        await BleManager.writeChar!.write(Uint8List.fromList(chunk), withoutResponse: false);
        setState(() => _uploadProgress = (i / totalBytes));
      } catch (e) {
        break;
      }
    }
    // End Command
    await BleManager.writeChar!.write(Uint8List.fromList([0x03, 0xFF, 0xFF]));
  }

  List<int> _int32ToBytes(int value) {
    return [(value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const Center(child: Text("Health Data Screen")),
            const DataScreen(),
            const Center(child: Text("Game Screen")),
            const Center(child: Text("Exercise Screen")),
            MeScreen(
              onConnect: _connect,
              isConnecting: _isConnecting,
              autoMirroring: _autoMirroring,
              onToggleMirroring: _toggleAutoMirroring,
              isConnected: BleManager.connectedDevice != null,
              onUploadImage: _pickAndUploadWatchFace,
              isUploading: _isUploading,
              uploadProgress: _uploadProgress,
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
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "GAME"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: "Exercise"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
    );
  }
}

// --- Data Screen (fl_chart) ---
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Heart Rate (BPM)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [const FlSpot(0, 72), const FlSpot(1, 75), const FlSpot(2, 70), const FlSpot(3, 82), const FlSpot(4, 78)],
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Me Screen ---
class MeScreen extends StatelessWidget {
  final Future<void> Function() onConnect;
  final bool isConnecting;
  final bool autoMirroring;
  final bool isConnected;
  final Future<void> Function(bool) onToggleMirroring;
  final VoidCallback onUploadImage;
  final bool isUploading;
  final double uploadProgress;

  const MeScreen({
    super.key, required this.onConnect, required this.isConnecting,
    required this.autoMirroring, required this.isConnected,
    required this.onToggleMirroring, required this.onUploadImage,
    required this.isUploading, required this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.watch, color: isConnected ? Colors.green : Colors.grey),
            title: Text(isConnected ? "Watch Connected" : "No Watch"),
            trailing: isConnecting ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: isConnected ? null : onConnect,
              child: const Text("Connect"),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (isUploading) ...[
          LinearProgressIndicator(value: uploadProgress, color: Colors.teal),
          Center(child: Text("${(uploadProgress * 100).toInt()}% Uploading...")),
        ],
        const Divider(),
        SwitchListTile(
          title: const Text("Notification Mirroring"),
          value: autoMirroring,
          onChanged: isConnected ? onToggleMirroring : null,
        ),
        ListTile(
          leading: const Icon(Icons.add_a_photo),
          title: const Text("Set Watch Face"),
          subtitle: const Text("Upload image from gallery"),
          onTap: isConnected && !isUploading ? onUploadImage : null,
        ),
      ],
    );
  }
}
