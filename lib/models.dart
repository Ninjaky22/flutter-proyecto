class AppUser {
  String name;
  String email;
  String role;
  bool active;

  AppUser({
    required this.name,
    required this.email,
    required this.role,
    this.active = false,
  });
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actor;
  final String action;
  final Map<String, dynamic>? details;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.action,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'actor': actor,
        'action': action,
        if (details != null) 'details': details,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
              DateTime.now(),
      actor: json['actor']?.toString() ?? 'unknown',
      action: json['action']?.toString() ?? 'unknown',
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'])
          : null,
    );
  }
}