// import 'dart:mirrors';

class LunartFramework {
  LunartFramework(this.config);

  final LunartConfig config;

  static LunartFramework boot(
    List<String> args, [
    LunartConfig config = const LunartConfig(),
  ]) {
    final framework = LunartFramework(config);

    framework.init(args);

    return framework;
  }

  void init(List<String> args) {
    print(args.first);
  }
}

class LunartConfig {
  const LunartConfig({this.controllerDir = '', this.viewsDir = ''});

  final String controllerDir;
  final String viewsDir;
}
