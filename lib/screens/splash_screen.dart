import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:custom_mazeapp/screens/level_selection.dart';
import 'package:custom_mazeapp/utils/Constants.dart';
import 'package:custom_mazeapp/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  DatabaseHelper helper = DatabaseHelper();
  late LevelItem levelItem;
  bool isLoading = false;
  List<LevelItem> listlevel = [];
  int count = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int? isexist = await helper.tableIsEmpty(0);
      if (isexist != 0) {
        Timer(Duration(seconds: 3), () {
          moveToNext();
        });
      } else {
        _save();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/maze.gif",
              height: 150,width: 150,),
            SizedBox(height: 25,),
            DefaultTextStyle(
              style: const TextStyle(
                  fontSize: 50.0,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Sunny"),
              child: AnimatedTextKit(
                totalRepeatCount: 10,
                animatedTexts: [
                  WavyAnimatedText('Maze Runner'),
                ],
                isRepeatingAnimation: true,
                onTap: () {
                  print("Tap Event");
                },
              ),
            )
          ],
        ),
      ),
    );
    ;
  }

  Future<void> moveToNext() async {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LevelSelection(),
        ));
  }

  // Save data to database
  void _save() async {
    setState(() {
      isLoading = true;
    });

    List<LevelItem> list0 =  Constants().getLevelList0();
    List<LevelItem> list1 =  Constants().getLevelList1();
    List<LevelItem> list2 = Constants().getLevelList2();

    for (var i = 0; i < list0.length; i++) {
      var currentElement = list0[i];
      await helper.insertLevel(currentElement, 0);
    }

    for (var i = 0; i < list1.length; i++) {
      var currentElement = list1[i];
      await helper.insertLevel(currentElement, 1);
    }

    for (var i = 0; i < list2.length; i++) {
      var currentElement = list2[i];
      await helper.insertLevel(currentElement, 2);
    }

    //after all the table data inserted then move to next...
    setState(()  {
      isLoading = false;
       moveToNext();
    });
  }
}
