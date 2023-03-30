/// FileName home
///
/// @Author liujunjie
/// @Date 2022/4/24 16:24
///
/// @Description 音乐主页
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:suplay_music/drop_down_menu.dart';
import 'package:suplay_music/player_widget.dart';

import 'audio_metadata.dart';

import 'package:audioplayers/audioplayers.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  List<AudioMetadata> playerModels = [];
  int currentPlayerIdx = 0;

  late AudioPlayer player;

  AudioMetadata? get currentPlayerModel {
    if (currentPlayerIdx >= playerModels.length) {
      return null;
    }

    return playerModels[currentPlayerIdx];
  }

  double sliderValue = 0.5;
  final _addGlobalKey = GlobalKey();

  @override
  void initState() {
    player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              menuList(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 70,
                child: Stack(
                  children: [
                    PlayerWidget(
                      player: player,
                      model: currentPlayerModel,
                      onPreviousPressed: () async {
                        int newIndex = currentPlayerIdx;
                        newIndex--;
                        newIndex %= playerModels.length;
                        await playMusic(index: newIndex);
                        setState(() {});
                      },
                      onNextPressed: () async {
                        int newIndex = currentPlayerIdx;
                        newIndex++;
                        newIndex %= playerModels.length;
                        await playMusic(index: newIndex);
                        setState(() {});
                      },
                    ),
                    Positioned(
                        top: 15,
                        right: 0,
                        child: IconButton(
                            key: _addGlobalKey,
                            onPressed: () {
                              Navigator.push(context, addAlertMenu());
                            },
                            icon: const Icon(Icons.add))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //添加弹出框，添加和清除音频
  DropDownMenuRouter addAlertMenu() {
    RenderBox renderBox =
    _addGlobalKey.currentContext?.findRenderObject() as RenderBox;
    Rect box = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    box = box.translate(-50, 0);
    return DropDownMenuRouter(
      position: box,
      menuWidth: 80,
      menuHeight: 60,
      itemView: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            TextButton(
                onPressed: () async {
                  await _openMusicFile();
                },
                child: const Text("添加音频")),
            TextButton(
                onPressed: () async {
                  await _clearAllMusic();
                },
                child: const Text("清除音频")),
          ],
        ),
      ),
    );
  }

  ///列表
  Widget menuList() {
    return Expanded(
      child: ReorderableListView.builder(
          itemBuilder: (context, index) {
            final mm = playerModels[index];

            return Dismissible(
              key: ValueKey(mm),
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
              onDismissed: (dismissDirection) async {
                playerModels.removeAt(index);

              },
              child: Material(
                color: index == currentPlayerIdx ? Colors.grey.shade300 : null,
                child: ListTile(
                  title: Text(mm.title),
                  onTap: () async {
                    await playMusic(index: index);
                    setState(() {});
                  },
                ),
              ),
            );
          },
          itemCount: playerModels.length,
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex--;
            playerModels.insert(newIndex, playerModels.removeAt(oldIndex));
          }),
    );
  }


  /// 添加本地音频
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
    EasyLoading.show();
    List<String> saveFlies = [];

    for (var f in files) {
      final name = f.name.replaceAll(RegExp(r'.mp3|.MP3|m4a|M4A'), '');
      final m =
      AudioMetadata(title: name, artwork: 'images/music.png', path: f.path);

      playerModels.add(m);
      saveFlies.add(m.toJsonString());
    }
    EasyLoading.dismiss();

    setState(() {});

    await playMusic();
  }

  Future<void> _clearAllMusic() async {
    EasyLoading.show();
    await player.release();
    playerModels.clear();

    EasyLoading.dismiss();
    setState(() {});
  }

  Future playMusic({int index = 0}) async {
    if (playerModels.isEmpty) return;
    if (player.state == PlayerState.playing) {
      await player.stop();
    }
    currentPlayerIdx = index;
    await player.play(DeviceFileSource(currentPlayerModel!.path));
  }
}
