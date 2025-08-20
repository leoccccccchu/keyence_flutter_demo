import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanTestPage extends StatefulWidget {
  const ScanTestPage({super.key});

  @override
  State<ScanTestPage> createState() => _ScanTestPageState();
}

class _ScanTestPageState extends State<ScanTestPage> {
  final s1 = TextEditingController();
  final s2 = TextEditingController();
  final s3 = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 👉 Run once when page is opened
    KeyenceScanner.scanController("ScanMode", "Default");
  }

  @override
  void dispose() {
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
                  labelText: 'String 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: s2,
                decoration: const InputDecoration(
                  labelText: 'String 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: s3,
                decoration: const InputDecoration(
                  labelText: 'String 3',
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
                  _btn('EANOnly', () => _onTap('EANOnly')),
                  _btn('LLWR', () => _onTap('LLWR')),
                  _btn('Button 5', () => _onTap('btn5')),
                  _btn('Button 6', () => _onTap('btn6')),
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
      case 'btn6':
        KeyenceScanner.scanController("Button6", "Action");
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
