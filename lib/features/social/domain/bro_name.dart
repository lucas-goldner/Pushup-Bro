import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// The public name every player gets, like "Banana Bro 4821": an adjective,
/// a noun and four digits. No player writes text that strangers see.
///
/// It is stored as its parts (`3.5.4821`), so everyone reads it in their
/// own language.
class BroName extends Equatable {
  const BroName(this.adjective, this.noun, this.digits);

  /// A random name.
  factory BroName.random([math.Random? random]) {
    final r = random ?? math.Random();

    return BroName(
      r.nextInt(_words['en']!.$1.length),
      r.nextInt(_words['en']!.$2.length),
      r.nextInt(10000),
    );
  }

  /// Parses [key] (`3.5.4821`); anything unreadable gives the first name,
  /// so a broken document still shows something friendly.
  factory BroName.parse(String? key) {
    final parts = (key ?? '').split('.').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) {
      return const BroName(0, 0, 0);
    }
    final count = _words['en']!;

    return BroName(
      parts[0]!.clamp(0, count.$1.length - 1),
      parts[1]!.clamp(0, count.$2.length - 1),
      parts[2]!.clamp(0, 9999),
    );
  }

  final int adjective;
  final int noun;
  final int digits;

  String get key => '$adjective.$noun.$digits';

  /// The name in [languageCode], falling back to English.
  String display(String languageCode) {
    final (adjectives, nouns) = _words[languageCode] ?? _words['en']!;
    final number = digits.toString().padLeft(4, '0');

    return languageCode == 'ja'
        ? '${adjectives[adjective]}${nouns[noun]} $number'
        : _nounFirst.contains(languageCode)
            ? '${nouns[noun]} ${adjectives[adjective]} $number'
            : '${adjectives[adjective]} ${nouns[noun]} $number';
  }

  @override
  List<Object?> get props => [adjective, noun, digits];
}

/// Languages that put the adjective after the noun.
const _nounFirst = {'es', 'pt'};

/// The word lists, in the same order in every language.
const Map<String, (List<String>, List<String>)> _words = {
  'en': (
    [
      'Banana',
      'Jungle',
      'Iron',
      'Sunny',
      'Mighty',
      'Calm',
      'Swift',
      'Happy',
      'Brave',
      'Lucky',
      'Golden',
      'Cosmic',
      'Turbo',
      'Chill',
      'Wild',
      'Royal',
    ],
    [
      'Bro',
      'King',
      'Gorilla',
      'Silverback',
      'Mango',
      'Coconut',
      'Vine',
      'Parrot',
      'Gecko',
      'Palm',
      'Lion',
      'Tiger',
      'Falcon',
      'Panda',
      'Comet',
      'Rocket',
    ],
  ),
  'de': (
    [
      'Bananen',
      'Dschungel',
      'Eisen',
      'Sonnen',
      'Mega',
      'Chill',
      'Blitz',
      'Happy',
      'Mutiger',
      'Glücks',
      'Gold',
      'Kosmos',
      'Turbo',
      'Lässiger',
      'Wilder',
      'Königs',
    ],
    [
      'Bro',
      'König',
      'Gorilla',
      'Silberrücken',
      'Mango',
      'Kokos',
      'Liane',
      'Papagei',
      'Gecko',
      'Palme',
      'Löwe',
      'Tiger',
      'Falke',
      'Panda',
      'Komet',
      'Rakete',
    ],
  ),
  'es': (
    [
      'Bananero',
      'Selvático',
      'de Hierro',
      'Soleado',
      'Poderoso',
      'Tranqui',
      'Veloz',
      'Feliz',
      'Valiente',
      'con Suerte',
      'Dorado',
      'Cósmico',
      'Turbo',
      'Relajado',
      'Salvaje',
      'Real',
    ],
    [
      'Bro',
      'Rey',
      'Gorila',
      'Espalda Plateada',
      'Mango',
      'Coco',
      'Liana',
      'Loro',
      'Geco',
      'Palmera',
      'León',
      'Tigre',
      'Halcón',
      'Panda',
      'Cometa',
      'Cohete',
    ],
  ),
  'pt': (
    [
      'Banana',
      'da Selva',
      'de Ferro',
      'Solar',
      'Poderoso',
      'Tranquilo',
      'Veloz',
      'Feliz',
      'Corajoso',
      'Sortudo',
      'Dourado',
      'Cósmico',
      'Turbo',
      'Relax',
      'Selvagem',
      'Real',
    ],
    [
      'Bro',
      'Rei',
      'Gorila',
      'Costas Prateadas',
      'Manga',
      'Coco',
      'Cipó',
      'Papagaio',
      'Lagartixa',
      'Palmeira',
      'Leão',
      'Tigre',
      'Falcão',
      'Panda',
      'Cometa',
      'Foguete',
    ],
  ),
  'ja': (
    [
      'バナナ',
      'ジャングル',
      '鋼の',
      '陽気な',
      '最強',
      'のんびり',
      '俊足',
      'ハッピー',
      '勇敢な',
      'ラッキー',
      '黄金の',
      '宇宙',
      'ターボ',
      'ゆるい',
      'ワイルド',
      'ロイヤル',
    ],
    [
      'ブロ',
      'キング',
      'ゴリラ',
      'シルバーバック',
      'マンゴー',
      'ココナッツ',
      'ツタ',
      'オウム',
      'ヤモリ',
      'ヤシ',
      'ライオン',
      'トラ',
      'ハヤブサ',
      'パンダ',
      '彗星',
      'ロケット',
    ],
  ),
};
