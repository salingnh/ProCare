import 'package:flutter/material.dart';

import 'src/ui/app.dart';
import 'src/ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const News2LApp(home: HomeScreen()));
}
