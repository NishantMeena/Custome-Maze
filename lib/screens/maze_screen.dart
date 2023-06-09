import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:custom_mazeapp/maze_widget.dart';
import 'package:custom_mazeapp/models/item.dart';
import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'package:custom_mazeapp/utils/AudioPlayerManager.dart';
import 'package:custom_mazeapp/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:custom_mazeapp/utils/Constants.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:quickalert/quickalert.dart';
import 'package:material_dialogs/material_dialogs.dart';

import '../utils/Constants.dart';

class MazeScreen extends StatefulWidget {
  int? id;
  int row = 0, column = 0, count = 0, dificulty = 0;
  String levelName = "";
  Color boxColor = Colors.green;

  MazeScreen(int id, String levelName, int row, int column, int count,
      int dificulty, Color boxColor) {
    this.id = id;
    this.levelName = levelName;
    this.row = row;
    this.column = column;
    this.count = count;
    this.dificulty = dificulty;
    this.boxColor = boxColor;
  }

  @override
  _MazeScreenState createState() =>
      _MazeScreenState(id!, levelName, row, column, count, dificulty, boxColor);
}

class _MazeScreenState extends State<MazeScreen> with WidgetsBindingObserver {
  int myRow = Constants.DEF_ROW_NUMBER;
  int myColumn = Constants.DEF_COLUMN_NUMBER;
  int myCount = 0;
  int dificultyLevel = 0;
  int? myId;
  String levelName = "";
  late int maxSecond;

  late int second;
  Timer? timer;
  bool isRunningTimer = false;
  bool isCompleated = false;
  bool isProgressColor = true;
  var isPlaying = false;
  var isPlayingR = false;
  DatabaseHelper helper = DatabaseHelper();
  List<MazeItem> pathList = [];
  Color boxColor = Colors.green;
  Color playerColor = Colors.blue;
  int sel = 0;
  AudioPlayer? player;
  AudioCache? audioCache;
  int timesPlayed = 0;
  bool shouldContinuePlaying = true;
  late final audioplaymanager;

  _MazeScreenState(int id, this.levelName, this.myRow, this.myColumn, int count,
      int dificulty, Color boxColor) {
    myCount = count;
    myId = id;
    dificultyLevel = dificulty;
    this.maxSecond = count;
    this.second = maxSecond;
  }

  void startTimer({bool reset = true}) {
    if (reset) {
      resetTimer(0);
    }
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (second > 0) {
          isProgressColor = true;
          second--;
        } else {
          isProgressColor = false;
          // it does not reset the timer
          stopTimer(reset: false, pause: 0);
          audioplaymanager.playAudioass(false);
          if (isPlaying == false) {
            playAudioonce('game_over.mp3');
          }
          showFailureDialog(context);
        }
      });
    });
    isRunningTimer = timer == null ? false : timer!.isActive;
    isCompleated = second == maxSecond || second == 0;
  }

  void resetTimer(int pause) {
    if (pause == 0) {
      second = maxSecond;
    }
  }

  void stopTimer({bool reset = true, int pause = 0}) {
    if (reset) {
      resetTimer(pause);
    }
    setState(() {
      timer?.cancel();
    });
  }


  @override
  void initState() {
    super.initState();
    if (dificultyLevel == 0) {
      boxColor = Colors.green;
      playerColor = Colors.red;
    } else if (dificultyLevel == 1) {
      boxColor = Colors.blue;
      playerColor = Colors.white;
    } else if (dificultyLevel == 2) {
      boxColor = Colors.red;
      playerColor = Colors.green;
    }
    mazePath(myRow, myColumn);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer(reset: false);
      audioplaymanager=AudioPlayerManager();
      audioplaymanager.playAudioass(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopTimer(reset: false, pause: 0);
    audioplaymanager.playAudioass(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      if (state == AppLifecycleState.paused) {
        stopTimer(reset: true, pause: 1);
      } else if (state == AppLifecycleState.resumed) {
        startTimer(reset: false);
      }
    });
  }

  void playAudioonce(String audio) async {
    player = AudioPlayer();
    audioCache = AudioCache();
    player = await audioCache?.play(audio);
  }

  bool isButtonDisabled = false;

  void handleClick() async {
    audioplaymanager.playAudioass(false);
    if (!isButtonDisabled) {
      setState(() {
        isButtonDisabled = true;
      });
      // Enable the button after 2 seconds
      Timer(Duration(seconds: 2), () {
        setState(() {
          isButtonDisabled = false;
        });
      });

      stopTimer(reset: true, pause: 0);
      onRestart(myId!, levelName, myRow, myColumn, myCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        audioplaymanager.playAudioass(false);
        goBack();
        return false;
      },
      child: Scaffold(
          body: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Column(
          children: [
            Expanded(
                flex: 10,
                child: Stack(
                  children: [
                    myMaze(context, myRow, myColumn),
                  ],
                )),
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 15,
                          ),
                          IconButton(
                              onPressed: handleClick,
                              icon: Icon(
                                Icons.refresh_outlined,
                                color: boxColor,
                              )),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  if (sel == 0) {
                                    sel = 1;
                                  } else {
                                    sel = 0;
                                  }
                                });
                              },
                              icon: sel == 0
                                  ? Icon(
                                      Icons.lightbulb_outline,
                                      color: boxColor,
                                    )
                                  : Icon(
                                      Icons.lightbulb,
                                      color: boxColor,
                                    ))
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 55,
                              height: 55,
                              child: Stack(fit: StackFit.expand, children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3,
                                  value: second / maxSecond,
                                ),
                                Center(child: buildTimer())
                              ]),
                            )
                          ],
                        )),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  if (isPlaying) {
                                    isPlaying = false;
                                    audioplaymanager.playAudioass(false);
                                  } else {
                                    isPlaying = true;
                                    audioplaymanager.playAudioass(true);
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
                          IconButton(
                              onPressed: () {
                                audioplaymanager.playAudioass(false);
                                goBack();
                              },
                              icon: Icon(
                                Icons.back_hand,
                                color: boxColor,
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      )),
    );
  }

  Widget buildTimer() {
    return second > 0
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              formatedTime(second),
              style: TextStyle(
                  fontFamily: "Sunny",
                  color: second > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
            ),
          )
        : Text("");
  }

  Widget myMaze(BuildContext context, int row, int column) {
    return Maze(
        sel: sel,
        playerColor: playerColor,
        player: MazeItem("assets/ghost.png", ImageType.asset),
        playerUp: MazeItem("assets/ghostupper.png", ImageType.asset),
        playerDown: MazeItem("assets/ghostdownmove.png", ImageType.asset),
        playerLeft: MazeItem("assets/ghostleftmove.png", ImageType.asset),
        playerRight: MazeItem("assets/ghostrightmove.png", ImageType.asset),
        columns: myColumn,
        rows: myRow,
        wallThickness: 4.0,
        wallColor: boxColor,
        pointColor: boxColor,
        finish: MazeItem('assets/finish.png', ImageType.asset),
        onDrawPath: (listPath) {},
        onFinish: () {
          isProgressColor = false;
          stopTimer(reset: false);
          audioplaymanager.playAudioass(false);
          if (isPlaying == false) {
            playAudioonce('success.mp3');
          }

          showDialog();
        });
  }

  // Dialogs
  void showDialog() {
    Dialogs.materialDialog(
      color: Colors.white,
      msg: 'Level Completed',
      title: 'Congratulations',
      lottieBuilder: Lottie.asset(
        'assets/cong_example.json',
        fit: BoxFit.contain,
      ),
      context: context,
      barrierDismissible: false,
      actions: [
        IconsButton(
          onPressed: () async {
            stopTimer(reset: true, pause: 0);
            LevelItem levelItem = LevelItem(
              (myId! + 1),
              levelName,
              1,
              myRow,
              myColumn,
              myCount,
            );

            int? lastid = await helper.getLastItemId(dificultyLevel) as int?;
            if (lastid != myId) {
              helper.updateLevel((myId! + 1), dificultyLevel);
              LevelItem levelItem = await helper.getLevel(
                (myId! + 1),
                dificultyLevel,
              ) as LevelItem;
              onRestart(
                levelItem.id!,
                levelItem.levelName,
                levelItem.row,
                levelItem.column,
                levelItem.count,
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(dificultyLevel),
                ),
              );
            }
            setState(() {});
          },
          text: 'Next',
          iconData: Icons.done,
          color: boxColor,
          textStyle: TextStyle(fontFamily: "Sunny", color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    ).then((value) async {
      stopTimer(reset: true, pause: 0);
      LevelItem levelItem = LevelItem(
        (myId! + 1),
        levelName,
        1,
        myRow,
        myColumn,
        myCount,
      );

      int? lastid = await helper.getLastItemId(dificultyLevel) as int?;
      if (lastid != myId) {
        helper.updateLevel((myId! + 1), dificultyLevel);
        LevelItem levelItem = await helper.getLevel(
          (myId! + 1),
          dificultyLevel,
        ) as LevelItem;
        onRestart(
          levelItem.id!,
          levelItem.levelName,
          levelItem.row,
          levelItem.column,
          levelItem.count,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(dificultyLevel),
          ),
        );
      }
    });
  }

  void showFailureDialog(BuildContext context) {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        title: 'Failure',
        titleColor: Colors.red,
        barrierColor: Colors.transparent.withAlpha(20),
        text: 'Level Time Exceed...',
        confirmBtnText: 'Game Restart',
        confirmBtnColor: Colors.red,
        barrierDismissible: false,
        animType: QuickAlertAnimType.slideInRight,
        onConfirmBtnTap: () {
          stopTimer(reset: true, pause: 0);
          onRestart(myId!, levelName, myRow, myColumn, myCount);
          setState(() {});
        });
  }

  void onRestart(int id, String level, int row, int column, int count) {
    audioplaymanager.playAudioass(false);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MazeScreen(
              id, level, row, column, count, dificultyLevel, boxColor),
        ));
  }

  void goBack() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(dificultyLevel),
        ));
  }

  Widget getVolumeIcon(bool isplay) {
    if (isplay) {
      return const Icon(Icons.volume_off);
    } else {
      return const Icon(Icons.volume_up);
    }
  }

  String formatedTime(int timeInSecond) {
    int sec = timeInSecond % 60;
    int min = (timeInSecond / 60).floor();
    if (min > 0) {
      String minute = min.toString().length <= 1 ? "0$min" : "$min";
      String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
      return "$minute : $second";
    } else {
      String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
      return second;
    }
  }

  void mazePath(int row, int column) {
    pathList = [];
    int sizeList = row * column;

    for (int i = 0; i <= (sizeList / 2); i++) {
      MazeItem mazeItem = MazeItem('assets/dot.png', ImageType.asset);
      pathList.add(mazeItem);
    }
    setState(() {});
  }
}
