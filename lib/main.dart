import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure SQLite database initialization before UI starts
  await AppDatabase.instance.database;

  runApp(const ProviderScope(child: ReceiptTrackerApp()));
}
