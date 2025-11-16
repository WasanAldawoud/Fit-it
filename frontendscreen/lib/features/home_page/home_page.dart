import 'package:flutter/material.dart';
//صفحة وهمية حتى تصميم صفحة

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 76, 93),
      appBar: AppBar(title: Text('Home Screen')),
      body: Center(),
    );
  }
}
