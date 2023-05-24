import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform, exit;
import 'package:audioplayers/audioplayers.dart';
import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:custom_mazeapp/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:custom_mazeapp/screens/maze_screen.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqlite_api.dart';

import 'level_selection.dart';

class DashboardScreen extends StatefulWidget {
  int dificulty=0;


  DashboardScreen(this.dificulty);

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int dificultyLevel=0;



  AudioPlayer player = AudioPlayer();
  AudioCache audioCache = AudioCache();
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<LevelItem> listlevel = [];
  int count = 0;
  bool isPlaying = false;
  static const snackBarDuration = Duration(seconds: 3);
  late DateTime backButtonPressTime;
  AppLifecycleState? _lastLifecycleState;
  late Color boxColor;

  @override
  void initState() {
    super.initState();
    dificultyLevel=widget.dificulty;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getList();
      if(dificultyLevel==0){
        boxColor=Colors.green;
      }else if(dificultyLevel==1){
        boxColor=Colors.blue;
      }else if(dificultyLevel==2){
        boxColor=Colors.red;
      }
      playAudio();
    });
  }

  void getList() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<LevelItem>> noteListFuture = databaseHelper.getLevelList(dificultyLevel);
      noteListFuture.then((listlevel) {
        setState(() {
          this.listlevel = listlevel;
          count = listlevel.length;
        });
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecycleState = state;
      if(state==AppLifecycleState.paused){
        stopAudio();
      }else if(state==AppLifecycleState.resumed){
        playAudio();
      }
    });
  }

  void playAudio() async {
    int timesPlayed = 0;
    const timestoPlay = 10;
    player = await audioCache.play('puzzle_begning.mp3');
    player.onPlayerCompletion.listen((event) {
      timesPlayed++;
      if (timesPlayed >= timestoPlay) {
        timesPlayed = 0;
        player.stop();
        isPlaying = false;
      } else {
        player.resume();
        isPlaying = true;
      }
    }); // assign player here
  }

  void stopAudio() async{
    await player?.stop();
    await player?.pause();
    await player?.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    listlevel.isEmpty
        ? ""
        : print(">>>>>build block ${listlevel[0].levelName}");

    return listlevel.isEmpty
        ? Container(
            color: Colors.transparent,
            height: 100,
            width: 100,
          )
        : Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text("Maze Level",style: TextStyle(fontFamily:"Sunny", color: boxColor,fontSize: 16),),),
          body: SafeArea(
            child: WillPopScope(
                onWillPop: () async {
                  stopAudio();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelSelection(),
                      ));
                  return false;
                },
                child:Column(
                  children: [
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 100,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                if (listlevel[index].isOpen == 1) {
                                  onStartGame(
                                      listlevel[index].id!,
                                      listlevel[index].levelName,
                                      listlevel[index].row,
                                      listlevel[index].column,
                                      listlevel[index].count);
                                  setState(() {});
                                }
                              },
                              child: Card(
                                shadowColor:boxColor,
                                color: boxColor,
                                elevation: 10,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      children: [getLevelStatusWidget(index)],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          itemCount: listlevel.length,
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isPlaying) {
                                        isPlaying = false;
                                        playAudio();
                                      } else {
                                        isPlaying = true;

                                        stopAudio();
                                      }
                                    });
                                  },
                                  icon: isPlaying
                                      ? Icon(
                                    Icons.volume_off,
                                    color: boxColor,
                                  )
                                      : Icon(
                                    Icons.volume_up,
                                    color: boxColor,
                                  )),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Center(
                                  child: IconButton(
                                      onPressed: () async{
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LevelSelection(),
                                            ));
                                      },
                                      icon: Icon(
                                        Icons.back_hand,
                                        color: boxColor,
                                      )),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ),
        );
  }

  Widget getLevelStatusWidget(int index) {
    return (listlevel[index].isOpen == 1)
        ? Text(
            listlevel[index].levelName,
            style: TextStyle(fontFamily:"Sunny",
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          )
        : Icon(
            Icons.lock,
            color: Colors.white,
          );
  }

  void onStartGame(int id, String level, int row, int column, int count) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MazeScreen(id, level, row, column, count,dificultyLevel,boxColor),
        ));
  }
}
