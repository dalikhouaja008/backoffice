import 'package:flutter/material.dart';

class ExpertPage extends StatelessWidget {
  const ExpertPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interface Expert'),
      ),
      body: Center(
        child: Text('Bienvenue dans l\'interface Expert'),
      ),
    );
  }
}