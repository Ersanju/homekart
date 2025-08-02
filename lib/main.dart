import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeKart Firebase Test',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const FirebaseTestPage(),
    );
  }
}

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  String message = 'Loading...';

  @override
  void initState() {
    super.initState();
    testFirestore();
  }

  Future<void> testFirestore() async {
    try {
      // Write data to Firestore
      await FirebaseFirestore.instance
          .collection('test')
          .doc('sample')
          .set({'message': 'Hello from HomeKart!'});

      // Read data from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('test')
          .doc('sample')
          .get();

      setState(() {
        message = snapshot.data()?['message'] ?? 'No message found.';
      });
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeKart Firebase Test'),
      ),
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
