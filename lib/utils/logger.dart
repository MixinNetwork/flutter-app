import 'package:logger/logger.dart';

import 'pretty_printer.dart' as printer;

final Logger logger = Logger(printer: printer.PrettyPrinter());

void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  logger.v(message, error, stackTrace);
}

void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  logger.d(message, error, stackTrace);
}

void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  logger.i(message, error, stackTrace);
}

void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  logger.w(message, error, stackTrace);
}

void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  logger.e(message, error, stackTrace);
}

void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  logger.wtf(message, error, stackTrace);
}
