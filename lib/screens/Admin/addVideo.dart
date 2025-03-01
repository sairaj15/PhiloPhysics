import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/services/docServices.dart';
import 'package:ephysicsapp/widgets/popUps.dart';
import 'package:flutter/material.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';

class AddVideo extends StatefulWidget {
  AddVideo({Key? key, required this.section, required this.moduleID}) : super(key: key);
  final String section;
  final String moduleID;

  @override
  State<AddVideo> createState() => _AddVideoState();
}

class _AddVideoState extends State<AddVideo> {
  TextEditingController videoNameController = TextEditingController();
  TextEditingController videoYtLinkController = TextEditingController();
  TextEditingController videothumbnailController = TextEditingController();

  final GlobalKey<FormState> _formKeyValue = GlobalKey<FormState>();

  String getThumbnailUrl(String videoUrl) {
    try {
      Uri uri = Uri.parse(videoUrl);
      String? videoId;

      // Handle standard YouTube URLs
      if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      }
      // Handle shortened YouTube URLs
      else if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      if (videoId == null || videoId.isEmpty) {
        throw Exception("Invalid video ID");
      }

      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } catch (e) {
      // Handle invalid URL or extraction error
      return 'https://img.youtube.com/vi/invalid/0.jpg'; // Placeholder thumbnail
    }
  }

  Future<void> getFuture() async {
     await addVideo(
      section: widget.section,
      moduleID: widget.moduleID,
      docName: videoNameController.text,
      docLink: videoYtLinkController.text,
      thumbnailLink: videothumbnailController.text,
      context: context,
    );
    showResultDialog(context, 'Process Complete');
  }

  void checkValidation() {
    if (_formKeyValue.currentState!.validate() &&
        videoNameController.text.isNotEmpty &&
        videoYtLinkController.text.isNotEmpty && videothumbnailController.text.isNotEmpty) {
      showProgress(context);
    } else {
      showToast("Please enter details and select files");
    }
  }

  Future<void> showProgress(BuildContext context) async {
    try {
      var result = await showDialog(
        builder: (context) => FutureProgressDialog(getFuture(), message: Text('Uploading...')),
        context: context,
      );
      showResultDialog(context, result);
    } catch (e) {
      // Handle any error that occurred during the progress dialog
      //showToast("An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      appBar: AppBar(
        title: Text("Add Video"),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKeyValue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                maxLines: 2 ,
                controller: videoNameController,
                validator: (value) {
                  if (value!.isEmpty) return "Add Video title";
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Add Video title",
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: videoYtLinkController,
                validator: (value) {
                  if (value!.isEmpty) return "Enter Video Link";
                  return null;
                },
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  labelText: "Enter Video Link",
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 2.0, color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: videothumbnailController,
                validator: (value) {
                  if (value!.isEmpty) return "Enter Video Thumbnail Link";
                  return null;
                },
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  labelText: "Enter Video Thumbnail Link",
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 2.0, color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                child: Text(
                  'Add Video',
                  style: TextStyle(color: color1),
                ),
                onPressed: checkValidation,
                style: ElevatedButton.styleFrom(backgroundColor: color4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
