/// Allowed values of [AppNotification.kind].
class NotificationKind {
  NotificationKind._();
  static const delay = 'delay';
  static const gate = 'gate';
  static const boarding = 'boarding';
  static const baggage = 'baggage';
  static const booking = 'booking';
}

/// An in-app (simulated push) notification.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime at;
  final bool read;

  /// One of [NotificationKind].
  final String kind;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
    required this.kind,
  });

  AppNotification copyWith({bool? read}) =>
      AppNotification(id: id, title: title, body: body, at: at, read: read ?? this.read, kind: kind);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'at': at.toIso8601String(),
        'read': read,
        'kind': kind,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        at: DateTime.parse(j['at'] as String),
        read: (j['read'] as bool?) ?? false,
        kind: j['kind'] as String,
      );

  @override
  String toString() => 'AppNotification($kind: $title)';
}
