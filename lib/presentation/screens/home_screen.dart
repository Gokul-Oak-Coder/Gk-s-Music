import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyAppState();
}

class _MyAppState extends State<HomeScreen> {
  final ValueNotifier<double> _valueNotifier = ValueNotifier(0.0);
  late DashedCircularProgressBar _controller;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late Future<List<SongModel>> _musicFuture;
  List<SongModel> _songs = [];
  final player = AudioPlayer();
  int? _currentIndex;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      _getLocalSongs();
    } else {}
  }

  Future<void> _getLocalSongs() async {
    List<SongModel> songs = await _audioQuery.querySongs(
      orderType: OrderType.ASC_OR_SMALLER,
      sortType: null,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() => _songs = songs);
  }

  void _playSong(SongModel song, int index) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      await _audioPlayer.play();

      _audioPlayer.positionStream.listen((position) {
        final duration = _audioPlayer.duration;
        if (duration != null && duration.inMilliseconds > 0) {
          final progress =
              position.inMilliseconds / duration.inMilliseconds * 100;
          _valueNotifier.value = progress.clamp(0, 100);
        }
      });
      setState(() {
        _currentIndex = index;
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  void _pauseSong() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _resumeSong() async {
    await _audioPlayer.play();
    setState(() => _isPlaying = true);
  }

  void _stopSong() async {
    await _audioPlayer.stop();
    _valueNotifier.value = 0.0;
    setState(() {
      _isPlaying = false;
      _currentIndex = null;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text(
          "Gk's Music",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            onPressed: () {
              initState();
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: _songs.isEmpty
          ? Center(child: Text("No Songs"))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final isSelected = _currentIndex == index;
                return ListTile(
                  title: Text(
                    song.title,
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: const Icon(
                    Icons.list,
                  ), // Icon on the left side of the ListTile.
                  trailing: isSelected
                      ? IconButton(
                          onPressed: () {
                            if (_isPlaying) {
                              _pauseSong();
                            } else {
                              _resumeSong();
                            }
                          },
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            setState(() {
                              buildShowBarModalBottomSheet(
                                context,
                                song.title,
                                song.duration,
                                _valueNotifier,
                              );
                            });
                            _playSong(song, index);
                          },
                        ),
                );
              },
            ),
    );
  }

  Future<dynamic> buildShowBarModalBottomSheet(
    BuildContext context,
    String title,
    int? duration,
    ValueNotifier<double> valueNotifier,
  ) {
    return showBarModalBottomSheet(
      isDismissible: true,
      context: context,
      // color is applied to main screen when modal bottom screen is displayed
      barrierColor: Colors.cyan,
      //background color for modal bottom screen
      backgroundColor: Colors.cyan.withValues(alpha: 0.1),
      //elevates modal bottom screen
      elevation: 10,
      // gives rounded corner to modal bottom screen
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      builder: (BuildContext context) {
        return SizedBox(
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Gk's Music"),
                Container(
                  padding: EdgeInsets.all(60),
                  child: DashedCircularProgressBar.aspectRatio(
                    aspectRatio: 1,
                    valueNotifier: valueNotifier,
                    progress: valueNotifier
                        .value, // e.g. 75% progress, can be dynamic
                    maxProgress: 100,
                    //startAngle: 225,
                    startAngle: 200,
                    sweepAngle: 320,
                    corners: StrokeCap.round,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    foregroundStrokeWidth: 10,
                    backgroundStrokeWidth: 10,
                    animation: true,
                    seekSize: 6,
                    seekColor: Colors.cyan,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, color: Colors.white, size: 30),
                          SizedBox(height: 10),
                          Text("Now Playing $title"),
                          SizedBox(height: 10),
                          Text(
                            "${valueNotifier.value.toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
