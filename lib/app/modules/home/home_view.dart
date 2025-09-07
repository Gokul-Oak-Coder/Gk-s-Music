import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gk_music/app/widgets/custom_player_controls.dart';
import 'package:just_audio/just_audio.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:smart_progress_circle/smart_progress_circle.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          "Gk's Music",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const Icon(Icons.menu, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.getLocalSongs(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            if (controller.songs.isEmpty) {
              return const Center(
                child: Text("No Songs", style: TextStyle(color: Colors.white)),
              );
            }

            return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                itemCount: controller.songs.length,
                itemBuilder: (context, index) {
                  final song = controller.songs[index];
                  final isSelected = controller.currentIndex.value == index;

                  return ListTile(
                    title: Text(
                      song.title,
                      style: const TextStyle(color: Colors.black),
                    ),
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkHeight: 50,
                      artworkWidth: 50,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.black,
                        size: 60,
                      ),
                    ),
                    trailing: isSelected
                        ? IconButton(
                            icon: Icon(
                              controller.isPlaying.value
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              controller.isPlaying.value
                                  ? controller.pauseSong()
                                  : controller.resumeSong();
                            },
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              controller.playSong(song, index);
                              //_showBottomSheet(context, song.title, controller);
                            },
                          ),
                  );
                },
              ),
            );
          }),
          // Now Playing Mini Player
          Obx(() {
            if (controller.currentSong == null) return const SizedBox();

            return Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  final song = controller.currentSong;
                  if (song != null) {
                    _showBottomSheet(context, song.title, song.id, controller);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Container(
                    color: Colors.cyan,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Song title and artwork
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              QueryArtworkWidget(
                                id: controller.currentSong!.id,
                                type: ArtworkType.AUDIO,
                                artworkHeight: 50,
                                artworkWidth: 50,
                                artworkFit: BoxFit.cover,
                                nullArtworkWidget: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                // Ensures the text doesn't overflow
                                child: Text(
                                  controller.currentSong!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Play/Pause + Next Buttons
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                controller.isPlaying.value
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                controller.isPlaying.value
                                    ? controller.pauseSong()
                                    : controller.resumeSong();
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                controller.nextSong();
                              },
                              icon: const Icon(
                                Icons.keyboard_double_arrow_right,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showBottomSheet(
    BuildContext context,
    String title,
    int? id,
    HomeController controller,
  ) {
    showBarModalBottomSheet(
      context: context,
      //backgroundColor: Colors.cyan,
      isDismissible: true,
      elevation: 10,
      backgroundColor: Colors.cyan,
      barrierColor: Colors.cyan,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      builder: (_) => SizedBox(
        height: double.infinity,
        child: Center(
          child: Obx(
            () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Gk's Music",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(60),
                  child: DashedCircularProgressBar.aspectRatio(
                    aspectRatio: 1,
                    valueNotifier: controller.progressNotifier,
                    progress: controller.progress.value,
                    maxProgress: 100,
                    startAngle: 200,
                    sweepAngle: 320,
                    corners: StrokeCap.round,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withAlpha(60),
                    foregroundStrokeWidth: 10,
                    backgroundStrokeWidth: 10,
                    animation: true,
                    seekSize: 6,
                    seekColor: Colors.cyan,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QueryArtworkWidget(
                              id: controller.currentSong!.id,
                              type: ArtworkType.AUDIO,
                              artworkHeight: 100,
                              artworkWidth: 100,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Now Playing: ${controller.currentSong?.title}",
                              style: TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${controller.progress.value.toStringAsFixed(0)}%",
                              style: const TextStyle(
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
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle Button
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: controller.isShuffleEnabled.value
                            ? Colors.white60
                            : Colors.white,
                      ),
                      onPressed: () => controller.toggleShuffle(),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.previousSong();
                      },
                      icon: Icon(
                        Icons.keyboard_double_arrow_left,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(
                        controller.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 70,
                      ),
                      onPressed: () {
                        controller.isPlaying.value
                            ? controller.pauseSong()
                            : controller.resumeSong();
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        controller.nextSong();
                      },
                      icon: Icon(
                        Icons.keyboard_double_arrow_right,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        controller.loopMode.value == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: controller.loopMode.value == LoopMode.off
                            ? Colors.white60
                            : Colors.white,
                      ),
                      onPressed: () => controller.toggleRepeatMode(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
