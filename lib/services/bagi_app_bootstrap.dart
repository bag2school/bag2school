import 'bagi_identity_bootstrap.dart';

class BagiAppBootstrap {
  BagiAppBootstrap._();

  static Future<void> initialize() async {
    await BagiIdentityBootstrap.initialize();
  }
}
