import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:marquee/marquee.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../../../helper/song_helper.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.cyan),
              child: Text('Drawer Header'),
            ),
            ListTile(title: const Text('Item 1'), onTap: () {}),
            ListTile(title: const Text('Item 2'), onTap: () {}),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text("Version 1.0.0"),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          "Gk's Music",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(Icons.menu, color: Colors.white),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              controller.isSearching.value = !controller.isSearching.value;
              controller.searchText.value = '';
            },
          ),
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
            return Column(
              children: [
                // Show search bar if searching
                if (controller.isSearching.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: InkWell(
                      focusColor: Colors.transparent,
                      onTap: () {
                        controller.filteredSongs;
                      },
                      child: Container(
                        height: 55, // Adjust height as needed
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade50,
                          border: Border.all(
                            color: Colors.cyan.withOpacity(0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.cyan,
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          autofocus: true,
                          cursorColor: Colors.cyan,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            hintText: 'Search songs...',
                            filled: true,
                            fillColor: Colors.transparent,
                            prefixIcon: Icon(Icons.search, color: Colors.cyan),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.close, color: Colors.cyan),
                              onPressed: () {
                                controller.searchText.value = '';
                                controller.isSearching.value = false;
                              },
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            controller.searchText.value = value;
                          },
                        ),
                      ),
                    ),
                  ),

                // List based on search or full list
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.isSearching.value
                        ? controller.filteredSongs.length
                        : controller.songs.length,
                    itemBuilder: (context, index) {
                      final list = controller.isSearching.value
                          ? controller.filteredSongs
                          : controller.songs;
                      final song = list[index];
                      final actualIndex = controller.songs.indexOf(song);
                      final isSelected =
                          controller.currentIndex.value == actualIndex;

                      return InkWell(
                        onTap: () {
                          controller.playSong(song, actualIndex);
                          controller.isSearching.value = false;
                          controller.searchText.value = '';
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    QueryArtworkWidget(
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      artworkHeight: 50,
                                      artworkWidth: 50,
                                      artworkFit: BoxFit.cover,
                                      nullArtworkWidget: const Icon(
                                        Icons.music_note,
                                        color: Colors.black,
                                        size: 50,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  isSelected
                                      ? Icon(
                                          Icons.play_arrow,
                                          color: Colors.red,
                                        )
                                      : SizedBox(),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
                                  size: 50,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: SizedBox(
                                  height: 20,
                                  child: Marquee(
                                    text: "${controller.currentSong?.title}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    scrollAxis: Axis.horizontal,
                                    blankSpace: 20.0,
                                    velocity: 50.0,
                                    pauseAfterRound: Duration(seconds: 1),
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
                                Icons.skip_next_outlined,
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
        //height: MediaQuery.of(context).size.height,
        child: Center(
          child: Obx(
            () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Gk's Music",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: SleekCircularSlider(
                            min: 0,
                            max: 100,
                            initialValue: controller.progress.value,
                            appearance: CircularSliderAppearance(
                              size: 200,
                              startAngle: 110,
                              angleRange: 320,
                              animationEnabled: true,
                              spinnerMode: false,
                              customWidths: CustomSliderWidths(
                                progressBarWidth: 10, // Foreground stroke width
                                handlerSize: 3,
                                trackWidth: 1, // Background stroke width
                              ),
                              customColors: CustomSliderColors(
                                progressBarColor:
                                    Colors.white, // Foreground color
                                //trackColor: Colors.white.withAlpha(60),
                                trackColor: Colors.white,
                                dotColor: Colors.cyan,
                                shadowColor: Colors.cyan,
                                gradientStartAngle: 110,
                                gradientEndAngle: 320,
                              ),
                            ),
                            onChange: (double value) {
                              // Convert slider value (0–100) to Duration
                              final totalDurationMs =
                                  controller.totalDuration.value.inMilliseconds;
                              final seekPositionMs =
                                  (value / 100 * totalDurationMs).round();
                              final seekDuration = Duration(
                                milliseconds: seekPositionMs,
                              );
                              controller.player.seek(seekDuration);
                              controller.currentPosition.value = seekDuration;
                              controller.progress.value = value;
                            },
                            onChangeStart: (_) {},
                            onChangeEnd: (_) {},
                            innerWidget: (double percentage) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                ),
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
                                          size: 50,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 20,
                                        child: Marquee(
                                          text:
                                              "Now Playing: ${controller.currentSong?.title}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          scrollAxis: Axis.horizontal,
                                          blankSpace: 20.0,
                                          velocity: 50.0,
                                          pauseAfterRound: const Duration(
                                            seconds: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "${SongHelper.formatDuration(controller.currentPosition.value)}"
                                        " / "
                                        "${SongHelper.formatDuration(controller.totalDuration.value)}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                    const SizedBox(width: 15),
                    IconButton(
                      onPressed: () {
                        controller.previousSong();
                      },
                      icon: Icon(
                        Icons.skip_previous_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        controller.nextSong();
                      },
                      icon: Icon(
                        Icons.skip_next_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
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
