/// FileName model
///
/// @Author liujunjie
/// @Date 2022/4/24 16:52
///
/// @Description TODO
import 'dart:convert';

class AudioMetadata {
  String title;
  String artwork;
  String path;

  AudioMetadata({
    required this.title,
    required this.artwork,
    required this.path,
  });

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      title: json['title'] as String,
      artwork: json['artwork'] as String,
      path: json['path'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'artwork': artwork,
        'path': path,
      };

  String toJsonString() {
    return jsonEncode(this);
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
