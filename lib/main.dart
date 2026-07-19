import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/notifications_service.dart';
// Rebuild trigger
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsService.init();
  runApp(const ProviderScope(child: DawaktiApp()));
}
