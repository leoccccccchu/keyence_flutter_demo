import 'package:flutter/material.dart';
import 'scan_test.dart'; // import your page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Keyence Scan Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScanTestPage(), // 👈 start from your page
    );
  }
}
  // // This widget is the root of your application.
  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'Flutter Demo',
  //     theme: ThemeData(
  //       // This is the theme of your application.
  //       //
  //       // TRY THIS: Try running your application with "flutter run". You'll see
  //       // the application has a purple toolbar. Then, without quitting the app,
  //       // try changing the seedColor in the colorScheme below to Colors.green
  //       // and then invoke "hot reload" (save your changes or press the "hot
  //       // reload" button in a Flutter-supported IDE, or press "r" if you used
  //       // the command line to start the app).
  //       //
  //       // Notice that the counter didn't reset back to zero; the application
  //       // state is not lost during the reload. To reset the state, use hot
  //       // restart instead.
  //       //
  //       // This works for code too, not just values: Most code changes can be
  //       // tested with just a hot reload.
  //       colorScheme: ColorScheme.fromSeed(
  //         seedColor: const Color.fromARGB(255, 50, 43, 155),
  //       ),
  //     ),
  //     home: const MyHomePage(title: 'Flutter Demo Home Page'),
  //   );
  // }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   // final String title;

//   // @override
//   // State<MyHomePage> createState() => _MyHomePageState();
// }

// // class _MyHomePageState extends State<MyHomePage> {
// //   int _counter = 0;

// //   void _incrementCounter() {
// //     setState(() {
// //       // This call to setState tells the Flutter framework that something has
// //       // changed in this State, which causes it to rerun the build method below
// //       // so that the display can reflect the updated values. If we changed
// //       // _counter without calling setState(), then the build method would not be
// //       // called again, and so nothing would appear to happen.
// //       _counter++;
// //     });
// //   }

//   @override
//   Widget build(BuildContext context) {
//     // KeyenceScanner.scanController("ScanMode", "Default"); //set to default
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             const SizedBox(height: 40),

//             // 👇 Add two buttons here
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   onPressed: () =>
//                       KeyenceScanner.scanController("lockScanner", "Lock"),
//                   child: const Text("Lock Scanner"),
//                 ),
//                 const SizedBox(width: 20), // spacing
//                 ElevatedButton(
//                   onPressed: () =>
//                       KeyenceScanner.scanController("lockScanner", "Unlock"),
//                   child: const Text("Unlock Scanner"),
//                 ),
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   onPressed: () =>
//                       KeyenceScanner.scanController("ScanMode", "EANOnly"),
//                   child: const Text("EAN"),
//                 ),
//                 const SizedBox(width: 20), // spacing
//                 ElevatedButton(
//                   onPressed: () =>
//                       KeyenceScanner.scanController("ScanMode", "LLWR"),
//                   child: const Text("LL WR"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
