import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  var songs = <SongModel>[].obs;
  //var currentIndex = RxnInt();
  var currentIndex = (-1).obs;
  var isPlaying = false.obs;
  final progressNotifier = ValueNotifier<double>(0.0);
  var progress = 0.0.obs;

  final Rx<LoopMode> loopMode = LoopMode.off.obs;
  final RxBool isShuffleEnabled = false.obs;
  ConcatenatingAudioSource? _playlist;

  SongModel? get currentSong =>
      currentIndex.value >= 0 ? songs[currentIndex.value] : null;

  @override
  void onInit() {
    super.onInit();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      await getLocalSongs();
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

  /*  Future<void> playSong(SongModel song, int index) async {
    if (index < 0 || index >= songs.length) return;

    final song = songs[index];
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      _audioPlayer.play();
      currentIndex.value = index;
      isPlaying.value = true;

      _audioPlayer.positionStream.listen((position) {
        final duration = _audioPlayer.duration;
        if (duration != null && duration.inMilliseconds > 0) {
          final value = position.inMilliseconds / duration.inMilliseconds * 100;
          progress.value = value.clamp(0, 100);
          */ /*progressNotifier.value =
              (position.inMilliseconds / duration.inMilliseconds * 100).clamp(
                0,
                100,
              );*/ /*
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'Cannot play song: $e');
    }
  }*/

  Future<void> playSong(SongModel song, int index) async {
    if (index < 0 || index >= songs.length) return;

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

      currentIndex.value = index;
      isPlaying.value = true;

      _audioPlayer.positionStream.listen((position) {
        final duration = _audioPlayer.duration;
        if (duration != null && duration.inMilliseconds > 0) {
          final value = position.inMilliseconds / duration.inMilliseconds * 100;
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
    //_audioPlayer.seekToNext();
    if (nextIndex < songs.length) {
      playSong(songs[nextIndex], nextIndex);
    }
  }

  void previousSong() {
    final prevIndex = currentIndex.value - 1;
    //_audioPlayer.seekToPrevious();
    if (prevIndex >= 0) {
      playSong(songs[prevIndex], prevIndex);
    }
  }

  /*void nextSong() {
    _audioPlayer.seekToNext();
  }

  void previousSong() {
    _audioPlayer.seekToPrevious();
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
    progress.value = 0.0;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
