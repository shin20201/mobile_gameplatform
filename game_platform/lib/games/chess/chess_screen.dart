import 'package:flutter/material.dart';

class ChessScreen extends StatelessWidget {
  const ChessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chess')),
      body: const SafeArea(child: Center(child: Text('Chess 게임 준비 중'))),
    );
  }
}
