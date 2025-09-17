import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  var songs = <SongModel>[].obs;
  var currentIndex = (-1).obs;
  var isPlaying = false.obs;
  final progressNotifier = ValueNotifier<double>(0.0);
  var progress = 0.0.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var isSearching = false.obs;
  var searchText = ''.obs;

  final Rx<LoopMode> loopMode = LoopMode.off.obs;
  final RxBool isShuffleEnabled = false.obs;
  ConcatenatingAudioSource? _playlist;

  SongModel? get currentSong =>
      currentIndex.value >= 0 ? songs[currentIndex.value] : null;
  AudioPlayer get player => _audioPlayer;

  List<SongModel> get filteredSongs {
    if (searchText.isEmpty) return [];
    return songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(searchText.value.toLowerCase()),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    bool permissionGranted;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (Platform.isAndroid && deviceInfo.version.sdkInt >= 33) {
      // Android 13+: Request media permissions
      permissionGranted = await Permission.audio.request().isGranted;
    } else {
      // Older Android: Request storage permission
      permissionGranted = await Permission.storage.request().isGranted;
    }
    if (permissionGranted) {
      await getLocalSongs();
    } else {
      Fluttertoast.showToast(
        msg:
            "Permission Denied, Please grant storage/audio permission to load songs",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> getLocalSongs() async {
    final data = await _audioQuery.querySongs(
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    songs.assignAll(data);
  }

  Future<void> playSong(SongModel song, int index) async {
    if (index < 0 || index >= songs.length) return;

    currentIndex.value = index;

    try {
      // Build playlist
      _playlist = ConcatenatingAudioSource(
        children: songs.map((s) => AudioSource.uri(Uri.parse(s.uri!))).toList(),
      );

      await _audioPlayer.setAudioSource(
        _playlist!,
        initialIndex: index,
        preload: true,
      );

      await _audioPlayer.setLoopMode(loopMode.value);
      await _audioPlayer.setShuffleModeEnabled(isShuffleEnabled.value);

      _audioPlayer.play();

      //currentIndex.value = index;
      isPlaying.value = true;

      _audioPlayer.positionStream.listen((position) {
        currentPosition.value = position;

        final duration = _audioPlayer.duration;
        if (duration != null && duration.inMilliseconds > 0) {
          totalDuration.value = duration;
          final value = position.inMilliseconds / duration.inMilliseconds * 100;
          progressNotifier.value = value.clamp(0, 100);
          progress.value = value.clamp(0, 100);
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          nextSong(); // Auto-play next song
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'Cannot play song: $e');
    }
  }

  void pauseSong() {
    _audioPlayer.pause();
    isPlaying.value = false;
  }

  void resumeSong() {
    _audioPlayer.play();
    isPlaying.value = true;
  }

  void nextSong() {
    final nextIndex = currentIndex.value + 1;
    if (nextIndex < songs.length) {
      playSong(songs[nextIndex], nextIndex);
    } else if (nextIndex == songs.length) {
      Get.snackbar("warning", "reached last");
    }
  }

  void previousSong() {
    final prevIndex = currentIndex.value - 1;
    if (prevIndex >= 0) {
      playSong(songs[prevIndex], prevIndex);
    }
  }

  /*  void nextSong() {
    try {
      if (currentIndex.value == songs.length) {
        Get.snackbar("warning", "last song");
      } else {
        currentIndex.value = currentIndex.value + 1;
        _audioPlayer.seekToNext();
      }
    } catch (e) {
      null;
    }
  }

  void previousSong() {
    try {
      if (currentIndex.value == songs.length) {
        Get.snackbar("warning", "last song");
      } else {
        currentIndex.value = currentIndex.value - 1;
        _audioPlayer.seekToPrevious();
      }
    } catch (e) {
      Get.snackbar("warning", "last song");
    }
  }*/

  void toggleShuffle() {
    isShuffleEnabled.value = !isShuffleEnabled.value;
    _audioPlayer.setShuffleModeEnabled(isShuffleEnabled.value);
  }

  void toggleRepeatMode() {
    if (loopMode.value == LoopMode.off) {
      loopMode.value = LoopMode.all;
    } else if (loopMode.value == LoopMode.all) {
      loopMode.value = LoopMode.one;
    } else {
      loopMode.value = LoopMode.off;
    }
    _audioPlayer.setLoopMode(loopMode.value);
  }

  void stopSong() {
    _audioPlayer.stop();
    isPlaying.value = false;
    currentIndex.value = 0;
    progressNotifier.value = 0.0;
    progress.value = 0.0;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
