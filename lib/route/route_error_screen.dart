import 'package:flutter/material.dart';

class RouteErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const RouteErrorScreen({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: onRetry == null
            ? Text(message)
            : ElevatedButton(onPressed: onRetry, child: Text(message)),
      ),
    );
  }
}
