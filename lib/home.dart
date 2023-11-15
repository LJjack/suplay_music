/// FileName home
///
/// @Author liujunjie
/// @Date 2022/4/24 16:24
///
/// @Description 音乐主页

import 'package:audio_session/audio_session.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'widgets/capacity_indicators.dart';
import 'widgets/popup.dart';

import 'audio_metadata.dart';
import 'widgets/control_buttons.dart';
import 'widgets/marquee.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late AudioPlayer _player;
  double sliderValue = 0.5;
  final _addGlobalKey = GlobalKey();
  final _playlist = ConcatenatingAudioSource(children: []);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      if (kDebugMode) {
        print('A stream error occurred: $e');
      }
    });
    try {
      await _player.setAudioSource(_playlist, preload: false);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading audio source: $e");
      }
    }

    await getSaveMusic();
  }

  Future<void> getSaveMusic() async {
    await _playlist.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.stop();
    }
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_menuList(), _bottomToolView()],
          ),
        ),
      ),
    );
  }

  ///列表
  Widget _menuList() {
    return Expanded(
      child: StreamBuilder<SequenceState?>(
        stream: _player.sequenceStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final sequence = state?.sequence ?? [];

          return ReorderableListView(
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) newIndex--;
              _playlist.move(oldIndex, newIndex);
            },
            children: [
              for (var i = 0; i < sequence.length; i++)
                Dismissible(
                  key: ValueKey(sequence[i]),
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                  onDismissed: (dismissDirection) async {
                    _playlist.removeAt(i);
                  },
                  child: Material(
                    color:
                        i == state!.currentIndex ? Colors.grey.shade300 : null,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: ListTile(
                        title: Text(sequence[i].tag.title as String),
                        trailing: Text(handleTime(sequence[i].duration ?? const Duration(seconds: 0))),
                        onTap: () {
                          _player.seek(Duration.zero, index: i);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomToolView() {
    return Container(
      color: const Color(0xFFF5F2F0),
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _musicInfoView(),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _settingsBtnView(),
                ),
              ],
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(
            children: [
              ControlButtons(player: _player),
              SizedBox(width: 400, child: _progressBarView())
            ],
          )
        ])
      ]),
    );
  }

  /// 播放当前音频的信息
  Widget _musicInfoView() {
    return StreamBuilder<SequenceState?>(
      stream: _player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state?.sequence.isEmpty ?? true) {
          return const SizedBox();
        }
        final metadata = state!.currentSource!.tag as AudioMetadata;
        return Row(
          children: [
            Container(
              margin: const EdgeInsets.all(8.0),
              width: 60,
              height: 60,
              child: Image.asset(metadata.artwork),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShowNameText(metadata.title),
                StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;

                    final textTime = handleTime(positionData?.position) +
                        " / " +
                        handleTime(positionData?.duration);

                    return Text(textTime,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54));
                  },
                )
              ],
            )
          ],
        );
      },
    );
  }

  ///进度条
  Widget _progressBarView() {
    return StreamBuilder<PositionData>(
      stream: _positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        final position = positionData?.position ?? Duration.zero;
        final duration = positionData?.duration ?? Duration.zero;
        final bufferedPosition =
            positionData?.bufferedPosition ?? Duration.zero;
        return CapacityIndicator(
          color: Colors.red,
          bufferedColor: Colors.red.shade100,
          initialValue: position.inMilliseconds.toDouble(),
          max: duration.inMilliseconds.toDouble(),
          bufferedValue: bufferedPosition.inMilliseconds.toDouble(),
          onChanged: (v) {
            _player.seek(Duration(milliseconds: v.round()));
          },
        );
      },
    );
  }

  Widget _settingsBtnView() {
    return IconButton(
        key: _addGlobalKey,
        onPressed: () {
          RenderBox renderBox =
              _addGlobalKey.currentContext?.findRenderObject() as RenderBox;
          Rect box = renderBox.localToGlobal(Offset.zero) & renderBox.size;
          box = box.translate(-60, -60);
          Popup.showPopupWindow(
              context: context,
              offset: box.topLeft,
              child: (closeFunc) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        TextButton(
                            onPressed: () async {
                              await _openMusicFile();
                            },
                            child: const Text("添加音频")),
                        TextButton(
                            onPressed: () async {
                              await _playlist.clear();
                            },
                            child: const Text("清除音频")),
                      ],
                    ),
                  ));
        },
        icon: const Icon(Icons.settings_rounded));
  }

  /// 获取本地音频
  Future<void> _openMusicFile() async {
    const XTypeGroup mp3TypeGroup = XTypeGroup(
      label: 'MP3',
      extensions: <String>['mp3', 'MP3'],
    );

    const XTypeGroup m4aTypeGroup = XTypeGroup(
      label: 'm4a',
      extensions: <String>['m4a', 'M4A'],
    );

    final List<XFile> files = await openFiles(
        acceptedTypeGroups: <XTypeGroup>[mp3TypeGroup, m4aTypeGroup]);
    if (files.isEmpty) return;

    List<String> saveFlies = [];

    for (var f in files) {
      final name = f.name.replaceAll(RegExp(r'.mp3|.MP3|m4a|M4A'), '');
      final m =
          AudioMetadata(title: name, artwork: 'images/music.png', path: f.path);
      await _playlist.add(AudioSource.uri(Uri.file(f.path), tag: m));
      saveFlies.add(m.toJsonString());
    }
    await _player.load();
  }

  String handleTime(Duration? duration) {
    if (duration == null) return '';

    return RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
            .firstMatch("$duration")
            ?.group(1) ??
        '$duration';
  }

  Widget _buildShowNameText(String txt) {
    return SizedBox(
        width: 150,
        height: 30,
        child: Marquee(
          text: txt,
          style: const TextStyle(
            fontSize: 14,
          ),
          blankSpace: 20.0,
          startPadding: 10.0,
        ));
  }
}
