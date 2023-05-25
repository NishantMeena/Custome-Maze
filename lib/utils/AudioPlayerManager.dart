import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerManager {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;

  Future<void> playAudio(String filePath) async {
    int result = await audioPlayer.play(filePath, isLocal: true);
    if (result == 1) {
      isPlaying = true;
      audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
  }

  void playAudioass(bool isPlay){
   /* final assetsAudioPlayer = AssetsAudioPlayer();

    if(isPlay){
      assetsAudioPlayer.open(
        Audio("assets/audio/game_music.mp3"),
      );
    }else{
      assetsAudioPlayer.stop();
    }*/

  }


  void stopAudioMang(){

  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    isPlaying = false;
  }
}