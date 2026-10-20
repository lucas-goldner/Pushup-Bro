import 'package:audioplayers/audioplayers.dart';
import 'package:pushup_bro/core/provider/audio_player_interface.dart';

class AudioPlayerProvider implements AudioPlayerInterface {
  AudioPlayerProvider(this.player);
  final AudioPlayer player;

  @override
  Future<void> playSound(String asset) async {
    await player.stop();
    await player.play(AssetSource(asset));
  }

  @override
  Future<void> setVolumeLevel(double volume) async {
    await player.setVolume(volume);
  }
}
