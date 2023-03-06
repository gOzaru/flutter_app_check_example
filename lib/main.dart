import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_check_example/firebase.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  await start();
  runApp(MainApp());
}

Future start() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp().then((value) async {
    await FirebaseAppCheck.instance.activate();
    await Get.putAsync(() => Cloud().init());
  });
}

class MainApp extends StatelessWidget {
  MainApp({super.key});
  final Cloud cloud = Get.find();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      smartManagement: SmartManagement.full,
      title: 'App Check',
      home: Scaffold(
        body: Center(
          child: ElevatedButton(onPressed: () => signUp(), child: const Text("Sign Up with Google")),
        ),
      ),
    );
  }

  void signUp() async {
    await cloud.signUpWithGoogle().then((value) {
      if (value["system"] == "success") {
        Get.defaultDialog(
          title: "Message",
          middleText: value["message"],
          confirm: ElevatedButton(
            onPressed: () {
              Get.offAll(() => MainMenu());
            },
            child: const Text("Ok"),
          ),
        );
      } else {
        Get.defaultDialog(
          title: "Warning",
          middleText: value["message"],
          confirm: ElevatedButton(
            onPressed: () {
              SystemNavigator.pop();
              exit(0);
            },
            child: const Text("Ok"),
          ),
        );
      }
    });
  }
}

class MainMenu extends StatelessWidget {
  MainMenu({super.key});
  final Cloud cloud = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Hello ${cloud.displayName}. \nHow do you do?")),
    );
  }
}
