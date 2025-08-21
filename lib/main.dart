import 'package:flutter/material.dart';
// import your page
import 'scan_test.dart';
import 'api_test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'CDN Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(), // 👈 start from your page
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training WMS')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Scan Test"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanTestPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("API Test"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApiTestPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
