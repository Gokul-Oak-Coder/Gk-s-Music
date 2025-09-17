class SongHelper {
  static String formatDuration1(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  static String formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, "0");
  }
}
