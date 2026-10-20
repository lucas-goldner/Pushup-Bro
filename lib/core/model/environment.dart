enum Environment {
  dev,
  prod,
}

extension FlavorTypeExtension on Environment {
  String getFlavorName() {
    switch (this) {
      case Environment.dev:
        return 'dev';
      case Environment.prod:
        return 'prod';
    }
  }
}
