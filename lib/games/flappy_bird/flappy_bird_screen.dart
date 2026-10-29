import 'package:flutter/material.dart';

class FlappyBirdScreen extends StatelessWidget {
  const FlappyBirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flappy Bird')),
      body: const SafeArea(child: Center(child: Text('Flappy Bird 게임 준비 중'))),
    );
  }
}
