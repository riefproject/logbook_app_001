import 'package:flutter/material.dart';
import '../log_controller.dart';

class OnlineStatusIndicator extends StatelessWidget {
  const OnlineStatusIndicator({super.key, required this.controller});
  final LogController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isOnlineNotifier,
      builder: (_, isOnline, _ ) => Tooltip(
        message: isOnline ? 'Online' : 'Offline',
        child: Icon(
          isOnline ? Icons.wifi : Icons.wifi_off,
          color: isOnline ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
