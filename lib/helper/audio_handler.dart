import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    // Listen to playback state and update notification controls
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: [0, 1, 2],
        playing: state.playing,
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
      ));
    });
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> skipToNext() => _player.seekToNext();
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// Custom method to update the playlist and start playback at [index]
  Future<void> setPlaylist(List<MediaItem> items, int index) async {
    // Broadcast the queue
    queue.add(items);

    // Stop any current playback
    await _player.stop();

    // Build a fresh playlist
    final source = ConcatenatingAudioSource(
      children: items
          .map((item) =>
          AudioSource.uri(Uri.parse(item.id), tag: item))
          .toList(),
    );

    // Set the playlist and play starting at [index]
    await _player.setAudioSource(source, initialIndex: index);
    mediaItem.add(items[index]); // Update current media item
    await _player.play();
  }
}
