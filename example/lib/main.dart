// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_core_network/flutter_core_network.dart';
import 'package:network_example/home_screen.dart';

void main() {
  // Initialize the network service
  NetworkService.initialize(
    const NetworkConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      enableLogging: true,
      maxRetries: 3,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Core Network Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
