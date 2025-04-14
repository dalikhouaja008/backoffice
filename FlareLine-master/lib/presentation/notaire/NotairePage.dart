import 'package:flutter/material.dart';

class NotairePage extends StatelessWidget {
  const NotairePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interface Notaire'),
      ),
      body: Center(
        child: Text('Bienvenue dans l\'interface Notaire'),
      ),
    );
  }
}
