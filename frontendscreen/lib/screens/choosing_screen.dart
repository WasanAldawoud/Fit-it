import 'package:flutter/material.dart';
//صفحة وهميه حتى يتم اضافه تصميمي عمر يرجى تغيير اسم الكلاس الموجود في سطر 184 في signup class

class ChoosingScreen extends StatelessWidget {
  const ChoosingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 76, 93),
      appBar: AppBar(title: Text('choosing page ')),
      body: Center(),
    );
  }
}
