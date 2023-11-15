import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'audio_metadata.dart';
import 'marquee.dart';

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final AudioMetadata? model;
  final VoidCallback? onPreviousPressed;
  final VoidCallback? onNextPressed;

  const PlayerWidget({
    super.key,
    required this.player,
    required this.model,
    this.onPreviousPressed,
    this.onNextPressed,
  });

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;

  AudioPlayer get player => widget.player;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didUpdateWidget(covariant PlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _playerState = player.state;
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    _initStreams();
  }

  @override
  void deactivate() {
    super.deactivate();

    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Positioned(
              left: 0,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    width: 60,
                    height: 60,
                    child: Image.asset("images/music.png"),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShowNameText(widget.model?.title),
                      Text(
                          handleTime(_position) +
                              " / " +
                              handleTime(_duration),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54))
                    ],
                  )
                ],
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _btn(
                    onPressed: widget.onPreviousPressed,
                    icon: Icons.skip_previous,
                  ),
                  _btn(
                    onPressed: _isPlaying ? _pause : _play,
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  _btn(
                    onPressed: widget.onNextPressed,
                    icon: Icons.skip_next,
                  ),
                ],
              ),
              _progressBarView(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressBarView() {
    return SizedBox(
      height: 20,
      width: 400,
      child: SliderTheme(
        data: const SliderThemeData(
          thumbShape: RoundSliderThumbShape(
              //  滑块形状，可以自定义
              enabledThumbRadius: 8 // 滑块大小
              ),
          overlayShape: RoundSliderOverlayShape(
            // 滑块外圈形状，可以自定义
            overlayRadius: 15, // 滑块外圈大小
          ),
        ),
        child: Slider(
          onChanged: (v) {
            final duration = _duration;
            if (duration == null) {
              return;
            }
            final position = v * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (_position != null &&
                  _duration != null &&
                  _position!.inMilliseconds > 0 &&
                  _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
      ),
    );
  }

  Widget _btn({IconData? icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        iconSize: 40.0,
        icon: Icon(icon),
        color: Colors.cyan,
      ),
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _play() async {
    final position = _position;
    if (position != null && position.inMilliseconds > 0) {
      await player.seek(position);
    }
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Widget _buildShowNameText(String? txt) {
    return SizedBox(
        width: 150,
        height: 30,
        child: Marquee(
          text: txt ?? "---",
          style: const TextStyle(
            fontSize: 14,
          ),
          blankSpace: 20.0,
          startPadding: 10.0,
        ));
  }

  String handleTime(Duration? duration) {
    if (duration == null) return '';

    return RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
            .firstMatch("$duration")
            ?.group(1) ??
        '$duration';
  }
}
