import 'package:flutter/material.dart';
import 'package:custom_mazeapp/screens/splash_screen.dart';
import 'package:flutter/services.dart';

void main() => runApp(MazeApp());

class MazeApp extends StatelessWidget {
  late BuildContext context;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    this.context = context;
    return MaterialApp(
        title: 'Maze Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: Colors.black),
        home: SplashScreen());
  }
}
