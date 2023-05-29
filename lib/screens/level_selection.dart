import 'package:audioplayers/audioplayers.dart';
import 'package:buttons_flutter/buttons_flutter.dart';
import 'package:custom_mazeapp/screens/dashboard.dart';
import 'package:custom_mazeapp/screens/star_rating.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform, exit;

import 'package:flutter/services.dart';

class LevelSelection extends StatefulWidget {
  @override
  LevelSelectionState createState() => LevelSelectionState();
}

class LevelSelectionState extends State<LevelSelection>
    with WidgetsBindingObserver {
  AudioPlayer? player;

  AudioCache? audioCache;
  AppLifecycleState? _lastLifecycleState;
  bool isPlaying = false;

  Items item1 = Items(
      title: "Easy",
      img: "assets/stars.png",
      imgcolor: Colors.green,
      star_color: Colors.cyanAccent,
      isLast: false,
      id: 0,
  rating: 1.0);
  Items item2 = Items(
      title: "Classic",
      img: "assets/stars.png",
      imgcolor: Colors.blue,
      star_color: Colors.lightGreenAccent,
      isLast: false,
      id: 1,
      rating: 2.0);
  Items item3 = Items(
      title: "Hard",
      img: "assets/stars.png",
      imgcolor: Colors.red,
      star_color: Colors.lime,
      isLast: false,
      id: 2,
      rating: 3.0);
  Items item4 = Items(
      title: "Settings",
      img: "assets/theme.png",
      imgcolor: Colors.deepPurple,
      star_color: Colors.white,
      isLast: true,
      id: 3,
      rating: 0.0);

  @override
  Widget build(BuildContext context) {
    List<Items> myList = [item1, item2, item3, item4];
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
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
                                      ? StarRating(rating:data.rating,size:28.0,star_color:data.star_color)
                                      : Image.asset(data.img, width: 42),
                                  SizedBox(height: 3),
                                  Text(
                                    data.title,
                                    style: TextStyle(
                                      color: data.star_color,
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
                              if(isPlaying){
                                playAudio();
                                isPlaying=false;
                              }else{
                                stopAudio();
                                isPlaying=true;
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
      playAudio();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecycleState = state;
      if (state == AppLifecycleState.paused) {

      } else if (state == AppLifecycleState.resumed) {
        setState(() {});
      }
    });
  }

  void playAudio() async {
    player=AudioPlayer();
    audioCache=AudioCache();
    int timesPlayed = 0;
    const timestoPlay = 10;
    player = await audioCache?.play('magic.mp3');
    player?.onPlayerCompletion.listen((event) {
      timesPlayed++;
      if (timesPlayed >= timestoPlay) {
        timesPlayed = 0;
        player?.stop();
      } else {
        player?.resume();
      }
    }); // assign player here
  }

  void stopAudio() {
    player?.stop();
  }

  void onItemClick(Items item) {
    if (item.id == 0 || item.id == 1 || item.id == 2) {
      stopAudio();
      moveNext(item.id);
    } else {
      //print("theme selectr");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Comming Soon'),
        backgroundColor: Colors.green,
      ));
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
  Color star_color;
  bool isLast;
  int id;
  double rating;

  Items(
      {required this.title,
      required this.img,
      required this.imgcolor,
      required this.star_color,
      required this.isLast,
      required this.id,
      required this.rating});
}
