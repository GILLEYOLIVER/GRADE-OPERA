import 'dart:math';

abstract final class IdGenerator {
  static final Random _random = Random();

  static String create(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}';
}
