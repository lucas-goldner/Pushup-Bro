class LevelScaler {
  static const Map<int, int> levelScaling = {
    1: 40,
    2: 60,
    3: 80,
    4: 120,
    5: 160,
    6: 200,
    7: 240,
    8: 280,
    9: 320,
    10: 360,
    11: 400,
    12: 440,
    13: 480,
    14: 520,
    15: 560,
    16: 600,
    17: 640,
    18: 680,
    19: 720,
    20: 760,
    21: 800,
    22: 840,
    23: 880,
    24: 920,
    25: 960,
    26: 1000,
    27: 1200,
    28: 1400,
    29: 1600,
    30: 1800,
    31: 2000,
    32: 2200,
    33: 2400,
    34: 2600,
    35: 2800,
    36: 3000,
    37: 3200,
    38: 3400,
    39: 3600,
    40: 3800,
    41: 4600,
    42: 5400,
    43: 6200,
    44: 7000,
    45: 7800,
    46: 8600,
    47: 9400,
    48: 10200,
    49: 11000,
    50: 11800,
    51: 13000,
    52: 14200,
    53: 15400,
    54: 16600,
    55: 17800,
    56: 19000,
    57: 20200,
    58: 21400,
    59: 22600,
    60: 23800,
  };

  num getLevelScaling(int level) => levelScaling[level] ?? 0;

  double getCurrentExperienceRelativeToLevel(
    int currentLevel,
    int level,
    int currentExperience,
  ) {
    var totalRequiredXP = 0;
    for (var i = currentLevel; i <= level; i++) {
      totalRequiredXP += getLevelScaling(i).toInt();
    }

    return currentExperience / totalRequiredXP;
  }
}
