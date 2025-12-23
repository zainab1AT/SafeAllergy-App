import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'constants.dart';

class Logger {
  Logger._();

  static final Logger _instance = Logger._();
  static Logger get instance => _instance;

  static Future<void> logInfo(String message, {String? context}) async {
    await _writeLog('INFO', message, context);
  }

  static Future<void> logWarning(String message, {String? context}) async {
    await _writeLog('WARNING', message, context);
  }

  static Future<void> logError(
    String message, {
    Object? error,
    String? context,
  }) async {
    final errorString = error != null ? _sanitizeError(error) : null;
    await _writeLog('ERROR', message, context, errorString);
  }

  static Future<void> logAudit(
    String action,
    String userId,
    String result, {
    String? details,
  }) async {
    final sanitizedUserId = _sanitizeUserId(userId);
    final logMessage =
        'AUDIT: $action | User: $sanitizedUserId | Result: $result';
    await _writeLog('AUDIT', logMessage, details);
  }

  static Future<void> _writeLog(
    String level,
    String message,
    String? context, [
    String? error,
  ]) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = StringBuffer();

      logEntry.writeln('[$timestamp] [$level] $message');
      if (context != null) {
        logEntry.writeln('  Context: $context');
      }
      if (error != null) {
        logEntry.writeln('  Error: $error');
      }
      logEntry.writeln('---');

      final directory = await getApplicationDocumentsDirectory();
      final logFile = File(
        '${directory.path}/${AppConstants.auditLogFileName}',
      );

      await logFile.writeAsString(logEntry.toString(), mode: FileMode.append);
    } catch (e) {}
  }

  static String _sanitizeError(Object error) {
    final errorString = error.toString();
    return errorString
        .replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b'), '[EMAIL_REDACTED]')
        .replaceAll(RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), '[PHONE_REDACTED]')
        .replaceAll(RegExp(r'\b\d{10,}\b'), '[NUMBER_REDACTED]');
  }

  static String _sanitizeUserId(String userId) {
    if (userId.contains('@')) {
      final parts = userId.split('@');
      if (parts.length == 2) {
        return 'user@${parts[1]}'; // Preserve domain, redact username
      }
    }
    return '[USER_REDACTED]';
  }

  static Future<void> clearLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File(
        '${directory.path}/${AppConstants.auditLogFileName}',
      );
      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }
}
