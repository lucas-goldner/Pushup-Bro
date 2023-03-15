import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pushup_bro/provider/audio_player_provider.dart';

import '../../mocks/mock_third_party/mock_audio_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final AudioPlayer audioPlayer = MockAudioPlayer();
  final audioPlayerProvider = AudioPlayerProvider(audioPlayer);

  group('test AudioPlayerProvider', () {
    test('test playSound', () async {
      final asset = AssetSource('');
      when(audioPlayer.stop).thenAnswer((_) => Future.value());
      when(() => audioPlayer.play(asset)).thenAnswer((_) => Future.value());

      await audioPlayerProvider.playSound(
        assetsource: asset,
        asset: asset.path,
      );
      verify(audioPlayer.stop);
      verify(() => audioPlayer.play(asset));
    });

    test('test setVolumeLevel', () async {
      when(() => audioPlayer.setVolume(1)).thenAnswer((_) => Future.value());
      await audioPlayerProvider.setVolumeLevel(1);

      verify(() => audioPlayer.setVolume(1));
    });
  });
}
