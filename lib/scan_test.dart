import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanTestPage extends StatefulWidget {
  const ScanTestPage({super.key});
  @override
  State<ScanTestPage> createState() => _ScanTestPageState();
}

class _ScanTestPageState extends State<ScanTestPage> {
  // static const _ch = MethodChannel('keyence_scanner/methods');
  static const _events = EventChannel('keyence_scanner/events');
  StreamSubscription? _sub;
  String last = '';

  final s1 = TextEditingController();
  final s2 = TextEditingController();
  final s3 = TextEditingController();

  @override
  void initState() {
    super.initState();

    // _ch.setMethodCallHandler((call) async {
    //   if (call.method == 'onScan') {
    //     final String code = call.arguments as String; // just a String
    //     setState(() => last = code);
    //     s2.text = last;
    //   }
    // });
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final scans = (event as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // for (final s in scans) {
        //   final idx = s['Index'] as int;
        //   final type = s['CodeType'] as String;
        //   final data = s['Data'] as String;
        // }

        final ctrls = [s1, s2, s3];
        for (var i = 0; i < ctrls.length; i++) {
          if (i < scans.length) {
            ctrls[i].text = '${scans[i]["CodeType"]}:${scans[i]["Data"]}';
          } else {
            ctrls[i].clear();
          }
        }
      },
      onError: (e) {
        setState(() => last = 'error: $e');
      },
    );
    // 👉 Run once when page is opened
    // KeyenceScanner.scanController("ScanMode", "Default");
  }

  @override
  void dispose() {
    _sub?.cancel();
    s1.dispose();
    s2.dispose();
    s3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Mode Demo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 3 string fields
              TextField(
                controller: s1,
                decoration: const InputDecoration(
                  labelText: 'Barcode 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: s2,
                decoration: const InputDecoration(
                  labelText: 'Barcode 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: s3,
                decoration: const InputDecoration(
                  labelText: 'Barcode 3',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 6 buttons (2 columns × 3 rows)
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3.2, // wider buttons
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _btn('Lock', () => _onTap('Lock')),
                  _btn('Unlock', () => _onTap('Unlock')),
                  _btn('EAN Only', () => _onTap('EANOnly')),
                  _btn('LLWR Mode', () => _onTap('LLWR')),
                  _btn('Button 5', () => _onTap('btn5')),
                  _btn('Clear', () => _onTap('Clear')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }

  void _onTap(String id) {
    // Interact with the scanner
    switch (id) {
      case 'Lock':
        KeyenceScanner.scanController("lockScanner", "Lock");
        break;
      case 'Unlock':
        KeyenceScanner.scanController("lockScanner", "Unlock");
        break;
      case 'EANOnly':
        KeyenceScanner.scanController("ScanMode", "EANOnly");
        break;
      case 'LLWR':
        KeyenceScanner.scanController("ScanMode", "LLWR");
        break;
      case 'btn5':
        KeyenceScanner.scanController("Button5", "Action");
        break;
      case 'Clear':
        // KeyenceScanner.scanController("Clear", "Clear");
        final ctrls = [s1, s2, s3];
        for (var i = 0; i < ctrls.length; i++) {
          ctrls[i].clear();
        }
        break;
    }
  }
}

class KeyenceScanner {
  static const _channel = MethodChannel('keyence_scanner/methods');
  static Future<void> scanController(String method, String argument) async {
    await _channel.invokeMethod(method, argument);
  }
}
