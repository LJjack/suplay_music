/// FileName model
///
/// @Author liujunjie
/// @Date 2022/4/24 16:52
///
/// @Description TODO
import 'dart:convert' show jsonEncode;

class AudioMetadata {
  ///名称
  final String title;

  ///封面 base64
  final String artwork;

  ///作者
  final String artist;

  ///歌词
  final String lyrics;
  final String path;

  AudioMetadata({
    required this.title,
    this.artist = '',
    this.artwork = '',
    this.lyrics = '',
    required this.path,
  });

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      title: json['title'],
      artist: json['artist'],
      artwork: json['artwork'] ?? '',
      lyrics: json['lyrics'] ?? '',
      path: json['path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'artist': artist,
        'artwork': artwork,
        'lyrics': lyrics,
        'path': path,
      };

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
