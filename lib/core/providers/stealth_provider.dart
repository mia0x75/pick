import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StealthMode { locked, glowing, unlocked }

class StealthNotifier extends StateNotifier<StealthMode> {
  StealthNotifier() : super(StealthMode.locked);

  void startUnlockSequence() {
    if (state == StealthMode.locked) {
      state = StealthMode.glowing;
    }
  }

  void verifyCode(List<int> inputSequence) {
    if (state != StealthMode.glowing) return;

    const defaultCode = [0, 1, 2, 3, 4]; // up, down, left, right, enter
    if (inputSequence.length == defaultCode.length &&
        inputSequence.asMap().entries.every((e) => e.value == defaultCode[e.key])) {
      state = StealthMode.unlocked;
    } else {
      state = StealthMode.locked;
    }
  }

  void lock() {
    state = StealthMode.locked;
  }
}

final stealthProvider = StateNotifierProvider<StealthNotifier, StealthMode>((ref) {
  return StealthNotifier();
});
