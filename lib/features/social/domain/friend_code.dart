import 'dart:math' as math;

/// Friend codes: six letters and digits, shown as `4K2-B7Q`.
///
/// Letters that are easy to mix up when read aloud or typed (0 and O, 1, I
/// and L) are left out, so a code is hard to get wrong.
abstract final class FriendCode {
  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const length = 6;

  /// A fresh random code, like `4K2B7Q`.
  static String generate([math.Random? random]) {
    final r = random ?? math.Random.secure();
    return String.fromCharCodes(
      List.generate(
        length,
        (_) => alphabet.codeUnitAt(r.nextInt(alphabet.length)),
      ),
    );
  }

  /// `4K2B7Q` as `4K2-B7Q`.
  static String format(String code) => code.length == length
      ? '${code.substring(0, 3)}-${code.substring(3)}'
      : code;

  /// What a player typed or pasted, as a code: upper case, without spaces,
  /// dashes or a pasted link around it. Letters outside the alphabet stay,
  /// so [isValid] can reject them.
  static String normalize(String input) {
    var text = input.trim();
    final link = RegExp('/pb/([A-Za-z0-9-]+)').firstMatch(text);
    if (link != null) text = link.group(1)!;

    return text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  }

  static bool isValid(String code) =>
      code.length == length && code.split('').every(alphabet.contains);

  /// The link a QR code carries; the iOS camera opens it in the app.
  static String link(String code) => 'https://lucas-goldner.com/pb/$code';
}
