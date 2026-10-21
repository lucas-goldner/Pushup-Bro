abstract class AudioPlayerInterface {
  Future<void> setVolumeLevel(double volume);
  Future<void> playSound(String asset);
}
