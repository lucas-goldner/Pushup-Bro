import 'package:pushup_bro/main_prod.dart' as prod;

/// The prod entrypoint moved to `lib/main_prod.dart`; this keeps the old
/// `-t lib/flavor/main_prod.dart` path working for the GitHub Actions iOS
/// build until the workflow is updated.
void main() => prod.main();
