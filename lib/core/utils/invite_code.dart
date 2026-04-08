import 'dart:math';

class InviteCodeGenerator {
  InviteCodeGenerator._();

  static final _random = Random.secure();
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate() {
    final suffix = List.generate(6, (_) => _chars[_random.nextInt(_chars.length)]).join();
    return 'LOVE-$suffix';
  }
}
