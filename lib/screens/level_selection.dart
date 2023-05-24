import 'package:audioplayers/audioplayers.dart';
import 'package:buttons_flutter/buttons_flutter.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'package:custom_mazeapp/utils/background_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform, exit;

import 'package:flutter/services.dart';

class LevelSelection extends StatefulWidget {
  @override
  LevelSelectionState createState() => LevelSelectionState();
}

class LevelSelectionState extends State<LevelSelection> with WidgetsBindingObserver{
  AudioPlayer player = AudioPlayer();
  AudioCache audioCache = AudioCache();
  AppLifecycleState? _lastLifecycleState;
  bool isPlaying = false;

  Items item1 = Items(
      title: "Easy",
      img: "assets/stars.png",
      imgcolor: Colors.green,
      isLast: false,
      id: 0);
  Items item2 = Items(
      title: "Classic",
      img: "assets/stars.png",
      imgcolor: Colors.blue,
      isLast: false,
      id: 1);
  Items item3 = Items(
      title: "Hard",
      img: "assets/stars.png",
      imgcolor: Colors.red,
      isLast: false,
      id: 2);
  Items item4 = Items(
      title: "Theme",
      img: "assets/theme.png",
      imgcolor: Colors.deepPurple,
      isLast: true,
      id: 3);

  @override
  Widget build(BuildContext context) {
    List<Items> myList = [item1, item2, item3, item4];
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async{
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else if (Platform.isIOS) {
            exit(0);
          }
          return false;
        },
        child: Column(
          children: [
            Expanded(
              flex: 10,
              child: Container(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Select option",
                        style: TextStyle(
                          fontFamily: "Sunny",
                          fontSize: 30,
                          color: Colors.deepOrange,
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: myList.map((data) {
                          return GestureDetector(
                            onTap: () {
                              onItemClick(data);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: data.imgcolor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  data.isLast == false
                                      ? ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            Colors.white, // Specify the desired color
                                            BlendMode.srcIn,
                                          ),
                                          child: Image.asset(
                                            data.img,
                                            width: 42,
                                          ),
                                        )
                                      : Image.asset(data.img, width: 42),
                                  SizedBox(height: 3),
                                  Text(
                                    data.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: "Sunny",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
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
                            color: Colors.deepOrange.shade400,
                          )
                              : Icon(
                            Icons.volume_up,
                            color: Colors.deepOrange.shade400,
                          )),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Center(
                          child: IconButton(
                              onPressed: () async {
                                if (Platform.isAndroid) {
                                  SystemNavigator.pop();
                                } else if (Platform.isIOS) {
                                  exit(0);
                                }
                              },
                              icon: Icon(
                                Icons.back_hand,
                                color: Colors.deepOrange.shade400,
                              )),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(player!=null&& isPlaying){
        stopAudio();
        playAudio();
      }else{
        playAudio();
      }
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
    player = await audioCache.play('magic.mp3');
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

  void onItemClick(Items item) {
    if (item.id == 0 || item.id == 1 || item.id == 2) {
      moveNext(item.id);
    } else {
      print("theme selectr");
    }
  }

  void moveNext(int deficulty) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(deficulty),
        ));
  }
}

class Items {
  String title;
  String img;
  Color imgcolor;
  bool isLast;
  int id;

  Items(
      {required this.title,
      required this.img,
      required this.imgcolor,
      required this.isLast,
      required this.id});
}
