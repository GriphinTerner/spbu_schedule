import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Переход на основной экран через 1 секунду
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка календаря
            const Icon(
              CupertinoIcons.calendar,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 30),
            // Текст "SPbU Schedule"
            const Text(
              'SPbU Schedule',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Текст "Project by Mr. Terner"
            const Text(
              'Project by Mr. Terner',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            // Индикатор загрузки
            const CupertinoActivityIndicator(
              radius: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}