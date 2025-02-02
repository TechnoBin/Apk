# Apk
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Database _database;
  TextEditingController _nameController = TextEditingController();
  List<String> _attendanceList = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'attendance.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE attendance(id INTEGER PRIMARY KEY, name TEXT)",
        );
      },
      version: 1,
    );
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final List<Map<String, dynamic>> maps = await _database.query('attendance');
    setState(() {
      _attendanceList = List.generate(maps.length, (i) => maps[i]['name']);
    });
  }

  Future<void> _markAttendance(String studentName) async {
    await _database.insert('attendance', {'name': studentName});
    _loadAttendance();
  }

  void _showQrDialog(String studentName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('QR Code for $studentName'),
        content: QrImageView(
          data: studentName,
          size: 200,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
        ],
      ),
    );
  }

  void _scanQr() async {
    final scannedName = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QrScannerScreen()),
    );
    if (scannedName != null) {
      _markAttendance(scannedName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("School Attendance")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Enter Student Name"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  _showQrDialog(_nameController.text);
                }
              },
              child: Text("Generate QR Code"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scanQr,
              child: Text("Scan QR Code"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _attendanceList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_attendanceList[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR Code")),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: (QRViewController controller) {
                this.controller = controller;
                controller.scannedDataStream.listen((scanData) {
                  setState(() {
                    result = scanData;
                  });
                  controller.pauseCamera();
                  Navigator.pop(context, result?.code);
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(result != null ? "Scanned: ${result!.code}" : "Scan a QR Code"),
            ),
          ),
        ],
      ),
    );
  }
}
