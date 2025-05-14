import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoUrl;
  final String videoName;

  const VideoDetailPage(
      {Key? key, required this.videoUrl, required this.videoName})
      : super(key: key);

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  late File _cacheFile;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    print(widget.videoUrl);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    String filename = widget.videoUrl.split('/').last;
    Directory dir = await getApplicationDocumentsDirectory();
    _cacheFile = File("${dir.path}/$filename");

    if (await _cacheFile.exists()) {
      print("Playing from cache: ${_cacheFile.path}");
      _videoPlayerController = VideoPlayerController.file(_cacheFile);
    } else {
      print("Playing from network & caching in background...");
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      _downloadAndCacheVideo(); // Start background download
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

  Future<void> _downloadAndCacheVideo() async {
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      var request = await HttpClient().getUrl(Uri.parse(widget.videoUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      await _cacheFile.writeAsBytes(bytes, flush: true);
      print("Video cached successfully: ${_cacheFile.path}");
    } catch (e) {
      print("Error caching video: $e");
    }

    _isDownloading = false;
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
            : SpinKitRotatingCircle(),
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
