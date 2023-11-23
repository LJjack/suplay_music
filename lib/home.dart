/// FileName home
///
/// @Author liujunjie
/// @Date 2022/4/24 16:24
///
/// @Description 音乐主页

import 'dart:convert' show base64;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:suplay_music/mixin_music.dart';

import 'audio_metadata.dart';
import 'detail.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin, MusicMixin {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }


  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      if (kDebugMode) {
        print('A stream error occurred: $e');
      }
    });
    try {
      await _player.setAudioSource(playList, preload: false);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading audio source: $e");
      }
    }

    await playList.clear();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print("--===--build--====---");
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _headView(),
            const Divider(),
            _menuList(),
            bottomToolView(onTap: () {
              _showCustomModalBottomSheet();
            })
          ],
        ),
      ),
    );
  }

  Widget _headView() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 30,
        child: Row(
          children: [
            Container(
                margin: const EdgeInsets.only(left: 8, right: 8),
                width: 40,
                child: const Text("图片",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("标题",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Expanded(
                      child: Text("演唱者",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  ///列表
  Widget _menuList() {

    return Expanded(
      child: StreamBuilder<SequenceState?>(
        stream: _player.sequenceStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final sequence = state?.sequence ?? [];
          print("--===--StreamBuilder--====---");
          return ListView(
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
                    playList.removeAt(i);
                  },
                  child: Material(
                    color:
                        i == state!.currentIndex ? Colors.grey.shade300 : null,
                    child: _menuCell(tag: sequence[i].tag, index: i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuCell({required AudioMetadata tag, required int index}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: ListTile(
        leading: SizedBox(
            width: 36,
            height: 36,
            child: tag.artwork.isNotEmpty
                ? Image.memory(
                    base64.decode(tag.artwork),
                  )
                : Image.asset('images/music.png')),
        title: Row(
          children: [
            Expanded(child: Text(tag.title)),
            Expanded(child: Text(tag.artist)),
          ],
        ),
        onTap: () {
          _player.seek(Duration.zero, index: index);
        },
      ),
    );
  }

  _showCustomModalBottomSheet() async {
    Navigator.of(context).push(MaterialPageRoute(builder: (cxt){
      return Detail(player: _player);
    }));
    return;
    Navigator.of(context).push(ModalBottomSheetRoute(
        constraints: BoxConstraints.tight(MediaQuery.of(context).size),
        builder: (context) {
          return Detail(player: _player);
        },
        isScrollControlled: true, enableDrag: false));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  AudioPlayer get player => _player;

}
