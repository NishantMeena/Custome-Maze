import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:custom_mazeapp/maze_widget.dart';
import 'package:custom_mazeapp/models/item.dart';
import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'package:custom_mazeapp/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:custom_mazeapp/utils/Constants.dart';
import 'package:flutter/services.dart';
import 'package:quickalert/quickalert.dart';

import '../utils/Constants.dart';

class MazeScreen extends StatefulWidget {
  int? id;
  int row = 0, column = 0, count = 0;
  String levelName = "";

  MazeScreen(int id, String levelName, int row, int column, int count) {
    this.id = id;
    this.levelName = levelName;
    this.row = row;
    this.column = column;
    this.count = count;
  }

  @override
  _MazeScreenState createState() =>
      _MazeScreenState(id!, levelName, row, column, count);
}

class _MazeScreenState extends State<MazeScreen> with WidgetsBindingObserver {
  int myRow = Constants.DEF_ROW_NUMBER;
  int myColumn = Constants.DEF_COLUMN_NUMBER;
  int myCount = 0;
  int? myId;
  String levelName = "";
  late var pref;
  static const maxSecond = 120;
  int second = maxSecond;
  Timer? timer;
  late bool isRunningTimer;
  late bool isCompleated;
  late bool isProgressColor = true;
  var isPlaying = true;
  DatabaseHelper helper = DatabaseHelper();
  List<MazeItem> pathList = [];

  _MazeScreenState(
      int id, String levelName, int myRow, int myColumn, int count) {
    this.levelName = levelName;
    this.myRow = myRow;
    this.myColumn = myColumn;
    this.myCount = count;
    this.myId = id;

    print("$myId $levelName $myRow $myColumn $myCount");
  }

  void startTimer({bool reset = true}) {
    if (reset) {
      resetTimer();
    }
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (second > 0) {
          isProgressColor = true;
          second--;
        } else {
          isProgressColor = false;
          // it does not reset the timer
          stopTimer(reset: false);
          showFailureDialog(context);
          stopAudio();
          playAudio('game_over.mp3', false);
        }
      });
    });
    isRunningTimer = timer == null ? false : timer!.isActive;
    isCompleated = second == maxSecond || second == 0;
  }

  void resetTimer() {
    second = maxSecond;
  }

  void stopTimer({bool reset = true}) {
    if (reset) {
      resetTimer();
    }
    setState(() {
      timer?.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    mazePath(myRow, myColumn);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer(reset: false);
      playAudio('puzzle_launch.mp3', true);
    });
  }

  AudioPlayer player = AudioPlayer();
  AudioCache audioCache = AudioCache();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player?.stop();
    player?.pause();
    player?.dispose();
    stopTimer(reset: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      if (state == AppLifecycleState.paused) {
        stopAudio();
      } else if (state == AppLifecycleState.resumed) {
        playAudio('puzzle_launch.mp3', true);
        startTimer(reset: false);
      }
    });
  }

  void playAudio(String audioPath, bool repeat) async {
    int timesPlayed = 0;
    const timestoPlay = 10;

    if (repeat == false) {
      player.stop();
      player = await audioCache.play(audioPath);
    } else {
      player = await audioCache.play(audioPath);
      player.onPlayerCompletion.listen((event) {
        timesPlayed++;
        if (timesPlayed >= timestoPlay) {
          timesPlayed = 0;
          player.stop();
        } else {
          player.resume();
          isPlaying = true;
        }
      });
    }
    // assign player here
  }

  void playOnce() {
    stopAudio();
  }

  void stopAudio() {
    player?.stop();
    player?.pause();
    player?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //SystemNavigator.pop();
        stopAudio();
        goBack();
        return false;
      },
      child: Scaffold(
          body: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Column(
          children: [
            Expanded(
                flex: 10,
                child: Stack(
                  children: [
                    Container(
                      height: 15,
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          'Level: $levelName',
                          style: TextStyle(
                              color: Colors.deepOrange.shade400,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
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
                              onPressed: () {
                                mazePath(myRow, myColumn);
                                setState(() {
                                  MazeState().getCellDetail();
                                });
                              },
                              icon: Icon(
                                Icons.account_tree_rounded,
                                color: Colors.deepOrange,
                              )),
                          IconButton(
                              onPressed: () {
                                onRestart(
                                    myId!, levelName, myRow, myColumn, myCount);
                              },
                              icon: Icon(
                                Icons.refresh_outlined,
                                color: Colors.deepOrange,
                              )),
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
                                    stopAudio();
                                  } else {
                                    isPlaying = true;
                                    playAudio('puzzle_launch.mp3', true);
                                  }
                                });
                              },
                              icon: isPlaying
                                  ? Icon(
                                      Icons.volume_up,
                                      color: Colors.green,
                                    )
                                  : Icon(
                                      Icons.volume_off,
                                      color: Colors.grey,
                                    )),
                          IconButton(
                              onPressed: () {
                                stopAudio();
                                goBack();
                              },
                              icon: Icon(
                                Icons.back_hand,
                                color: Colors.deepOrange.shade400,
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
                  color: second > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
            ),
          )
        : Text("");
  }

  Widget myMaze(BuildContext context, int row, int column) {

    return Maze(
        player: MazeItem('assets/running.png', ImageType.asset),
        columns: myColumn,
        rows: myRow,
       // checkpoints: pathList,
        wallThickness: 4.0,
        wallColor: Colors.deepOrange,
        pointColor: Colors.red,
        finish: MazeItem('assets/finish.png', ImageType.asset),
        onDrawPath: (listPath) {
          /*if(listPath!=null){
            print("Nishant cell List ${listPath.length}");
          }*/
        },
        onFinish: () {
          isProgressColor = false;
          stopTimer(reset: false);
          playAudio('success.mp3', false);
          showSuccessDialog(context);
        });
  }

  void showSuccessDialog(BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        titleColor: Colors.green,
        barrierColor: Colors.transparent.withAlpha(5),
        text: 'Level Cleared...',
        barrierDismissible: false,
        confirmBtnText: 'Next',
        confirmBtnColor: Colors.green,
        onConfirmBtnTap: () async {
          LevelItem levelItem =
              LevelItem((myId! + 1), levelName, 1, myRow, myColumn, myCount);

          int? lastid = (await helper.getLastItemId()) as int?;
          if (lastid != myId) {
            helper.updateLevel((myId! + 1));
            LevelItem levelItem =
                await helper.getLevel((myId! + 1)) as LevelItem;
            onRestart(levelItem.id!, levelItem.levelName, levelItem.row,
                levelItem.column, levelItem.count);
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(),
                ));
          }

          setState(() {});
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
          onRestart(myId!, levelName, myRow, myColumn, myCount);

          setState(() {});
        });
  }

  void onRestart(int id, String level, int row, int column, int count) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MazeScreen(id, level, row, column, count),
        ));
  }

  void goBack() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(),
        ));
  }

  Widget getVolumeIcon(bool isplay) {
    if (isplay) {
      //stopAudio();
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

  void mazePath(int row,int column){
    pathList=[];
    int sizeList=row*column;

    for(int i=0;i<=(sizeList/2);i++){
      MazeItem mazeItem=MazeItem('assets/dot.png' ,ImageType.asset);
      pathList.add(mazeItem);
    }
    setState(() {

    });
  }

}
