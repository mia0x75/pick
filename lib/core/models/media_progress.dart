class MediaProgress {
  final String mediaId;
  final String title;
  final int positionSec;
  final int durationSec;
  final DateTime updatedAt;
  final String deviceId;

  MediaProgress({
    required this.mediaId,
    required this.title,
    required this.positionSec,
    required this.durationSec,
    required this.updatedAt,
    required this.deviceId,
  });

  double get progressPercent =>
      durationSec > 0 ? positionSec / durationSec : 0.0;

  bool get isFinished => positionSec >= durationSec * 0.95;

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'title': title,
      'positionSec': positionSec,
      'durationSec': durationSec,
      'updatedAt': updatedAt.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory MediaProgress.fromJson(Map<String, dynamic> json) {
    return MediaProgress(
      mediaId: json['mediaId'] as String,
      title: json['title'] as String,
      positionSec: json['positionSec'] as int,
      durationSec: json['durationSec'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deviceId: json['deviceId'] as String,
    );
  }

  MediaProgress copyWith({
    String? mediaId,
    String? title,
    int? positionSec,
    int? durationSec,
    DateTime? updatedAt,
    String? deviceId,
  }) {
    return MediaProgress(
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      positionSec: positionSec ?? this.positionSec,
      durationSec: durationSec ?? this.durationSec,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
