import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:gk_music/app/modules/home/home_binding.dart';
import 'package:gk_music/presentation/screens/home_screen.dart';

import 'app/modules/home/home_view.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GetMaterialApp(
      title: "'Gk Music",
      initialBinding: HomeBinding(),
      theme: ThemeData(primarySwatch: Colors.cyan),
      //home: const HomeScreen(),
      home: const HomePage(),
    );
  }
}
