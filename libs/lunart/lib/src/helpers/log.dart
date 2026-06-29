import 'package:ansicolor/ansicolor.dart';
import 'dart:async';

enum LogType {
  log,
  info,
  error,
  warn,
  trace,
  debug;

  String get value {
    return switch (this) {
      (LogType.log) => 'LOG',
      (LogType.info) => 'INFO',
      (LogType.error) => 'ERROR',
      (LogType.warn) => 'WARN',
      (LogType.trace) => 'TRACE',
      (LogType.debug) => 'DEBUG',
    };
  }

  @override
  String toString() => value;
}

class LogEntry {
  final LogType type;
  final String message;
  final dynamic context;
  late final DateTime time;

  LogEntry({this.type = LogType.log, this.message = '', this.context}) {
    time = DateTime.now();
  }
}

class Logger {
  final controller = StreamController<LogEntry>.broadcast();

  Logger({List<void Function(LogEntry)>? listeners}) {
    if (listeners == null) return;

    for (final listener in listeners) {
      listen(listener);
    }
  }

  void listen(void Function(LogEntry) listener) {
    controller.stream.listen(listener);
  }

  void dispatch(LogEntry logEntry) {
    controller.add(logEntry);
  }
}

AnsiPen _getAnsiiPen(LogType type) {
  final pen = AnsiPen();
  return switch (type) {
    (LogType.log) => pen..black(bold: true),
    (LogType.info) => pen..green(bold: true),
    (LogType.error) => pen..red(bold: true),
    (LogType.warn) => pen..yellow(bold: true),
    (LogType.trace) => pen..blue(bold: true),
    (LogType.debug) => pen..magenta(bold: true),
  };
}

void consoleLogger(LogEntry entry) {
  final pen = _getAnsiiPen(entry.type);

  var log =
      '[${entry.time.toUtc()}] ${pen(entry.type.value.padRight(5))} ${entry.message}';

  if (entry.context != null) {
    log += ' ${entry.context}';
  }

  print(log);
}

sealed class Log {
  static var logger = Logger(listeners: [consoleLogger]);

  static void listen(void Function(LogEntry) listener) {
    logger.listen(listener);
  }

  static void log(String message, {dynamic context}) {
    logger.dispatch(
      LogEntry(type: LogType.log, message: message, context: context),
    );
  }

  static void info(String message, {dynamic context}) {
    logger.dispatch(
      LogEntry(type: LogType.info, message: message, context: context),
    );
  }

  static void error(String message, {dynamic context}) {
    logger.dispatch(
      LogEntry(type: LogType.error, message: message, context: context),
    );
  }

  static void warn(String message, {dynamic context}) {
    logger.dispatch(
      LogEntry(type: LogType.warn, message: message, context: context),
    );
  }

  static void trace(String message, {dynamic context}) {
    logger.dispatch(
      LogEntry(type: LogType.trace, message: message, context: context),
    );
  }

  static void debug(String message, {dynamic context}) {
    logger.dispatch(
      LogEntry(type: LogType.debug, message: message, context: context),
    );
  }
}
