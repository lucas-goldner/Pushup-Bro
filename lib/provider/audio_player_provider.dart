import 'package:audioplayers/audioplayers.dart';
import 'package:pushup_bro/provider/interface/audio_player_interface.dart';

class AudioPlayerProvider implements AudioPlayerInterface {
  AudioPlayerProvider(this.player);
  final AudioPlayer player;

  @override
  Future<void> playSound({
    required String asset,
    AssetSource? assetsource,
  }) async {
    await player.stop();
    await player.play(assetsource ?? AssetSource(asset));
  }

  @override
  Future<void> setVolumeLevel(double volume) async {
    await player.setVolume(volume);
  }
}
