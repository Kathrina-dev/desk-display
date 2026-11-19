import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'screens/stand_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
      title: 'Desk Display',
      debugShowCheckedModeBanner: false,
        //
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090909),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF141414),
          primary: Color(0xFFC44582),
        ),
    );
      home: const StandScreen(),
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
