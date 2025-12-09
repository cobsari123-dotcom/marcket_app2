class Sanction {
  final String id;
  final String userId;
  final String adminId;
  final SanctionType type;
  final String message;
  final DateTime timestamp;
  final SanctionStatus status;
  final SanctionDuration? duration;
  final String reason;

  Sanction({
    required this.id,
    required this.userId,
    required this.adminId,
    required this.type,
    required this.message,
    required this.timestamp,
    this.status = SanctionStatus.active,
    this.duration,
    required this.reason,
  });

  factory Sanction.fromMap(Map<String, dynamic> map, String id) {
    return Sanction(
      id: id,
      userId: map['userId'],
      adminId: map['adminId'],
      type: SanctionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => SanctionType.warning,
      ),
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      status: SanctionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => SanctionStatus.active,
      ),
      duration: map['duration'] != null
          ? SanctionDuration.values.firstWhere(
              (e) => e.toString().split('.').last == map['duration'],
              orElse: () => SanctionDuration.permanent,
            )
          : null,
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'adminId': adminId,
      'type': type.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'duration': duration?.toString().split('.').last,
      'reason': reason,
    };
  }

  Sanction copyWith({
    String? id,
    String? userId,
    String? adminId,
    SanctionType? type,
    String? message,
    DateTime? timestamp,
    SanctionStatus? status,
    SanctionDuration? duration,
    String? reason,
  }) {
    return Sanction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
    );
  }
}

enum SanctionType { warning, suspension, deletion }

enum SanctionStatus { active, resolved, appealed }

enum SanctionDuration { oneWeek, oneMonth, permanent, custom }
