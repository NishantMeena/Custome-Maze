import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:custom_mazeapp/maze_widget.dart';
import 'package:custom_mazeapp/models/item.dart';
import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'package:custom_mazeapp/screens/star_rating.dart';
import 'package:custom_mazeapp/utils/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:custom_mazeapp/utils/Constants.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:quickalert/quickalert.dart';
import 'package:material_dialogs/material_dialogs.dart';

class MazeScreen extends StatefulWidget {
  int? id;
  int row = 0, column = 0, stars = 0, count = 0, dificulty = 0;
  String levelName = "";
  Color boxColor = Colors.green;

  MazeScreen(int this.id, this.levelName, this.row, this.column, this.count,
      this.dificulty, this.boxColor, this.stars);

  @override
  _MazeScreenState createState() => _MazeScreenState(id!, levelName, row, column, count, dificulty, boxColor, stars);
}

class _MazeScreenState extends State<MazeScreen> with WidgetsBindingObserver {
  int myRow = Constants.DEF_ROW_NUMBER;
  int myColumn = Constants.DEF_COLUMN_NUMBER;
  int myCount = 0;
  int myStars = 0;
  int dificultyLevel = 0;
  int? myId;
  String levelName = "";
  late int maxSecond;

  late int second;
  int rankSecond = 0;
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
  bool solTapOnce = false;
  AudioPlayer? player;
  AudioCache? audioCache;
  int timesPlayed = 0;
  bool shouldContinuePlaying = true;
  late Color starColor;

  _MazeScreenState(int id, this.levelName, this.myRow, this.myColumn, int count,
      int dificulty, Color boxColor, int stars) {
    myCount = count;
    myStars = stars;
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
          rankSecond = second;
          second--;
        } else {
          isProgressColor = false;
          // it does not reset the timer
          stopTimer(reset: false, pause: 0);
          if (isPlaying == false) {
            playAudio('game_over.mp3', false);
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
    timer?.cancel();
    stopAudio();
  }

  @override
  void initState() {
    super.initState();
    if (dificultyLevel == 0) {
      boxColor = Colors.green;
      playerColor = Colors.red;
      starColor = Colors.cyanAccent;
    } else if (dificultyLevel == 1) {
      boxColor = Colors.blue;
      playerColor = Colors.white;
      starColor = Colors.lightGreenAccent;
    } else if (dificultyLevel == 2) {
      boxColor = Colors.red;
      playerColor = Colors.green;
      starColor = Colors.lime;
    }
    mazePath(myRow, myColumn);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      startTimer(reset: false);

      player = AudioPlayer();
      playAudio("game_music.mp3", true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    stopTimer(reset: false, pause: 0);
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

  /* Future<void> playAudioonce(String audio) async {
    await player?.setUrl(audio);
    player?.setReleaseMode(ReleaseMode.LOOP);
    player?.resume();
  }*/

  void playAudio(String path, bool isResume) async {
    player = AudioPlayer();
    audioCache = AudioCache();
    int timesPlayed = 0;
    const timestoPlay = 10;

    if (isResume == false) {
      player = await audioCache?.play(path);
    } else {
      player = await audioCache?.play(path);
      player?.onPlayerCompletion.listen((event) {
        timesPlayed++;
        if (timesPlayed >= timestoPlay) {
          timesPlayed = 0;
          player?.stop();
        } else {
          player?.resume();
        }
      });
    }
  }

  void stopAudio() {
    player?.stop();
  }

  bool isButtonDisabled = false;

  void handleClick() async {
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
      onRestart(myId!, levelName, myRow, myColumn, myCount, myStars);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        goBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          title: gsetTitleBar(),
        ),
        body: Column(
          children: [
            Expanded(
              child: myMaze(context, myRow, myColumn),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              padding: EdgeInsets.all(8.0),
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
                                  solTapOnce = true;
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              setState(() {
                                if (isPlaying) {
                                  isPlaying = false;
                                  playAudio("game_music.mp3", true);
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
                        IconButton(
                            onPressed: () {
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
            )
          ],
        ),
      ),
    );
  }

  Widget gsetTitleBar() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Level: $levelName",
            style: TextStyle(fontFamily: "Sunny", color: starColor),
          ),
          Visibility(
            visible: myStars != 0,
            child: Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                StarRating(
                  rating: myStars.toDouble(),
                  size: 10.0,
                  star_color: starColor,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.help_outline,
              color: starColor,
            ),
          ),
        ],
      ),
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
        : const Text("");
  }

  Widget myMaze(BuildContext context, int row, int column) {
    return Maze(
        sel: sel,
        playerColor: playerColor,
        player: MazeItem("assets/ghost.png", ImageType.asset),
        playerUp: MazeItem("assets/playerimage/playerup1.png", ImageType.asset),
        playerDown:
            MazeItem("assets/playerimage/playerdown1.png", ImageType.asset),
        playerLeft:
            MazeItem("assets/playerimage/playerleft1.png", ImageType.asset),
        playerRight:
            MazeItem("assets/playerimage/playerright1.png", ImageType.asset),
        columns: column,
        rows: row,
        wallThickness: 4.0,
        wallColor: boxColor,
        pointColor: boxColor,
        finish: MazeItem('assets/finish.png', ImageType.asset),
        onDrawPath: (listPath) {},
        onFinish: () {
          isProgressColor = false;
          stopTimer(reset: false);
          if (isPlaying == false) {
            playAudio('success.mp3', false);
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
            int? lastid = await helper.getLastItemId(dificultyLevel) as int?;
            if (lastid != myId) {
              helper.updateLevel((myId! + 1), dificultyLevel);
              // update stars
              helper.updateStars(
                  myId!, dificultyLevel, solTapOnce ? 1 : calculateStars());
              LevelItem levelItem = await helper.getLevel(
                (myId! + 1),
                dificultyLevel,
              ) as LevelItem;
              onRestart(levelItem.id!, levelItem.levelName, levelItem.row,
                  levelItem.column, levelItem.count, levelItem.stars);
            } else {
              gotoDashboard();
            }
            setState(() {});
          },
          text: 'Next',
          iconData: Icons.done,
          color: boxColor,
          textStyle: const TextStyle(fontFamily: "Sunny", color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    ).then((value) async {
      stopTimer(reset: true, pause: 0);

      int? lastid = await helper.getLastItemId(dificultyLevel) as int?;
      if (lastid != myId) {
        helper.updateLevel((myId! + 1), dificultyLevel);
        // update stars
        helper.updateStars(
            myId!, dificultyLevel, solTapOnce ? 1 : calculateStars());
        LevelItem levelItem = await helper.getLevel(
          (myId! + 1),
          dificultyLevel,
        ) as LevelItem;
        onRestart(levelItem.id!, levelItem.levelName, levelItem.row,
            levelItem.column, levelItem.count, levelItem.stars);
      } else {
       gotoDashboard();
      }
    });
  }

  void gotoDashboard(){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(dificultyLevel),
      ),
    );
  }

  int calculateStars() {
    // Define the time intervals for each star rating
    int threeStarInterval = (2 * maxSecond) ~/ 3;
    int twoStarInterval = (maxSecond) ~/ 3;
    int starRating;
    if (rankSecond >= threeStarInterval) {
      starRating = 3;
    } else if (rankSecond >= twoStarInterval) {
      starRating = 2;
    } else {
      starRating = 1;
    }
    return starRating;
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
          onRestart(myId!, levelName, myRow, myColumn, myCount, myStars);
          setState(() {});
        });
  }

  void onRestart(
      int id, String level, int row, int column, int count, int stars) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MazeScreen(
              id, level, row, column, count, dificultyLevel, boxColor, stars),
        ));
  }

  void goBack() {
   gotoDashboard();
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
