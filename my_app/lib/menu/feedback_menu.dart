import 'package:flutter/material.dart';

class FeedbackMenu extends StatelessWidget {
  const FeedbackMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: ListView(),
    );
  }
}