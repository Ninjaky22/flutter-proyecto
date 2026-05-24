import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AuditLogService {
  static const _key = 'audit_logs';

  static Future<void> log(
    String action, {
    String actor = 'system',
    Map<String, dynamic>? details,
  }) async {
    try {
      final entry = AuditLogEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        actor: actor,
        action: action,
        details: details,
      );

      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_key) ?? [];
      
      logs.add(jsonEncode(entry.toJson()));
      
      // Mantenemos los últimos 1000 registros para no saturar el storage
      if (logs.length > 1000) {
        logs.removeAt(0);
      }
      
      await prefs.setStringList(_key, logs);
      debugPrint('AuditLog: Logged $action by $actor (Total: ${logs.length})');
    } catch (e) {
      debugPrint('AuditLog Error: Failed to log $action - $e');
    }
  }

  static Future<List<AuditLogEntry>> getEntries({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_key) ?? [];
      final items = <AuditLogEntry>[];

      for (final logStr in logs) {
        try {
          final json = jsonDecode(logStr);
          items.add(AuditLogEntry.fromJson(Map<String, dynamic>.from(json)));
        } catch (e) {
          debugPrint('AuditLog Error: Failed to decode entry - $e');
        }
      }

      // Ordenar por fecha descendente (más recientes primero)
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (limit != null && items.length > limit) {
        return items.take(limit).toList();
      }
      return items;
    } catch (e) {
      debugPrint('AuditLog Error: Failed to get entries - $e');
      return [];
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('AuditLog Error: Failed to clear - $e');
    }
  }
}
