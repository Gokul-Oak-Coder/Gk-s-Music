import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gk_music/app/modules/home/home_binding.dart';
import 'app/modules/home/home_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "'Gk Music",
      initialBinding: HomeBinding(),
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: const HomePage(),
    );
  }
}
