import 'dart:io';

import 'package:logger/logger.dart';

class LoggerApi {
  late File logFile;
  late Logger logger;

  static final LoggerApi _singleton = LoggerApi._internal();

  factory LoggerApi([File? logFile]) {
    if (logFile != null) {
      _singleton.logFile = logFile;
      _singleton.logger = Logger(
        filter: null, // Use the default LogFilter (-> only log in debug mode)
        printer:
            PrettyPrinter(), // Use the PrettyPrinter to format and print log
        output: FileOutput(
            overrideExisting: true,
            file:
                logFile), // Use the default LogOutput (-> send everything to console)
      );
    }
    return _singleton;
  }

  LoggerApi._internal();

  void info(String message) {
    logger.i(message);
  }

  void error(String message) {
    logger.e(message);
  }

  void warning(String message) {
    logger.w(message);
  }
}
