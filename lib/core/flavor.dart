import 'package:pushup_bro/core/model/environment.dart';
import 'package:pushup_bro/core/model/flavor_config.dart';

class Flavor {
  static FlavorConfig _config = _Configs.debugConstants;

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.dev:
        _config = _Configs.debugConstants;
      case Environment.prod:
        _config = _Configs.prodConstants;
    }
  }

  static String get getCurrentEnvironment {
    return _config.flavor;
  }
}

class _Configs {
  static final FlavorConfig debugConstants = FlavorConfig('dev');
  static final FlavorConfig prodConstants = FlavorConfig('prod');
}
