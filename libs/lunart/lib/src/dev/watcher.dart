import 'dart:convert';
import 'dart:io';
import 'dart:async';

void watch(
  String mainFilePath, {
  String srcDirectoryPath = './lib',
  String dartPath = 'dart',
}) async {
  final mainFile = File(mainFilePath);
  final srcDirectory = Directory(srcDirectoryPath);

  final fileUpdateController = StreamController<FileSystemEvent>();
  final stdOutController = StreamController<List<int>>();

  stdOutController.stream.transform(utf8.decoder).forEach(stdout.write);

  mainFile.watch().listen((event) {
    fileUpdateController.add(event);
  });

  if (await srcDirectory.exists()) {
    srcDirectory.watch().listen((event) {
      fileUpdateController.add(event);
    });
  }

  var serverProcess = await _startServerProcess(dartPath, mainFilePath);

  serverProcess.stdout.listen((out) => stdOutController.add(out));

  Timer? timer;

  await for (final event in fileUpdateController.stream) {
    if (event.isDirectory) {
      continue;
    }

    if (event is! FileSystemModifyEvent) {
      continue;
    }

    if (!event.contentChanged) {
      continue;
    }

    timer?.cancel();

    timer = Timer(Duration(milliseconds: 5), () async {
      stdout.write('\x1B[2J\x1B[3J\x1B[H');
      serverProcess.kill();

      serverProcess = await _startServerProcess(dartPath, mainFilePath);

      print('${DateTime.now()}: Process Restarted!');
      serverProcess.stdout.listen((out) => stdOutController.add(out));
    });
  }
}

Future<Process> _startServerProcess(String dartPath, String mainFilePath) {
  return Process.start(dartPath, [mainFilePath]);
}
