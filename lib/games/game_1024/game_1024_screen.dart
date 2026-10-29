import 'package:flutter/material.dart';

class Game1024Screen extends StatelessWidget {
  const Game1024Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1024')),
      body: const SafeArea(child: Center(child: Text('1024 게임 준비 중'))),
    );
  }
}
