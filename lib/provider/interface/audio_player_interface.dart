import 'package:audioplayers/audioplayers.dart';

abstract class AudioPlayerInterface {
  Future<void> setVolumeLevel(double volume);
  Future<void> playSound({required String asset, AssetSource assetsource});
}
