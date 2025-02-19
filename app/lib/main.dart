import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:iris_app/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IrisApp());
}

class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  bool get _shouldAnimate {
    if (kIsWeb) return true;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return true;
  }

  bool get _supportsShaders {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final sdkInt =
          int.tryParse(Platform.operatingSystemVersion.split('.')[0]) ?? 0;
      return sdkInt >= 21;
    }
    if (Platform.isIOS) return true;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRIS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light, // Changed to light theme
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: HomeScreen(
        animated: _shouldAnimate && _supportsShaders,
      ),
    );
  }
}
