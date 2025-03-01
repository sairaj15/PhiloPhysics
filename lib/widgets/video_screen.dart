import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoUrl;
  final String videoName;

  const VideoDetailPage({Key? key, required this.videoUrl, required this.videoName})
      : super(key: key);

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    String filename = widget.videoUrl.split('/').last;
    Directory dir = await getApplicationDocumentsDirectory();
    File file = File("${dir.path}/$filename");

    if (await file.exists()) {
      print("Playing from cache: ${file.path}");
      _videoPlayerController = VideoPlayerController.file(file);
    } else {
      print("Downloading video and caching...");
      var request = await HttpClient().getUrl(Uri.parse(widget.videoUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes, flush: true);
      _videoPlayerController = VideoPlayerController.file(file);
    }

    await _videoPlayerController.initialize();
    print("Video player initialized.");

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        draggableProgressBar: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          bufferedColor: Colors.grey,
          backgroundColor: Colors.black54,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.videoName,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    print("Video player disposed.");
    super.dispose();
  }
}
