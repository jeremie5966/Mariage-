import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingScan {
  const PendingScan({
    required this.eventId,
    required this.qrToken,
    required this.createdAt,
  });

  final int eventId;
  final String qrToken;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'qr_token': qrToken,
    'created_at': createdAt.toIso8601String(),
  };

  factory PendingScan.fromJson(Map<String, dynamic> json) => PendingScan(
    eventId: json['event_id'] as int,
    qrToken: json['qr_token'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class OfflineScanQueue {
  static const _key = 'pending_scans';

  Future<List<PendingScan>> all() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? [])
        .map(
          (value) =>
              PendingScan.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> enqueue(PendingScan scan) async {
    final preferences = await SharedPreferences.getInstance();
    final scans = await all();
    if (scans.any(
      (item) => item.eventId == scan.eventId && item.qrToken == scan.qrToken,
    )) {
      return;
    }
    await preferences.setStringList(
      _key,
      [...scans, scan].map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> replace(List<PendingScan> scans) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      scans.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
