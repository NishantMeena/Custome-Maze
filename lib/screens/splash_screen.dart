import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:custom_mazeapp/utils/Constants.dart';
import 'package:custom_mazeapp/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'dart:async';

import 'package:sqflite/sqflite.dart';

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
      int?  isexist=await helper.tableIsEmpty();
      if (isexist!=0) {
        Timer(Duration(seconds: 2), () {
          moveToNext();
        });
      } else {
        _save();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FUN GAME',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange),
            ),
            Container(
              height: 20,
            ),
            isLoading ? Text("Processing...") : Text("")
          ],
        ),
      ),
    );
  }

  void moveToNext() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(),
        ));
  }

  // Save data to database
  void _save() async {
    setState(() {
      isLoading = true;
    });
    List<LevelItem> list = Constants().getLevelList();

    for (var i = 0; i < list.length; i++) {
      var currentElement = list[i];
      await helper.insertLevel(currentElement);
      if (i == list.length - 1) {
        // move to next
        setState(() {
          isLoading = false;
          moveToNext();
        });
      }
    }
  }


}
