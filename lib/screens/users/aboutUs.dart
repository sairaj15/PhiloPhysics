import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/globals/labels.dart';
import 'package:ephysicsapp/globals/member.dart';
import 'package:ephysicsapp/widgets/generalWidgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intro_slider/intro_slider.dart';

class AboutUs extends StatefulWidget {
  AboutUs({Key? key}) : super(key: key);

  @override
  AboutUsState createState() => new AboutUsState();
}

class AboutUsState extends State<AboutUs> {
  List<ContentConfig> slides = [];
  List<Member> members = [];
  bool isLoadingSlides = true;

  late Function goToTab;

  @override
  void initState() {
    super.initState();

    // Static slides
    slides.add(
      newSlide(
        imgPath: "assets/sakec.jpg",
        discription: sakecDiscription,
        title: "About SAKEC",
      ),
    );
    slides.add(
      newSlide(
        imgPath: "assets/rc.png",
        discription: rcDiscription,
        title: "About Research Cell",
      ),
    );

    // Fetch members dynamically and add the team slide
    fetchMembers();
  }

  void fetchMembers() async {
    final ref = FirebaseDatabase.instance.ref("Members");

    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      List<Member> loadedMembers = [];

      data.forEach((key, value) {
        loadedMembers.add(Member.fromMap(value));
      });

      // Define the display order
      List<String> roleOrder = [
        "Principal",
        "Mentor",
        "V1-Developer",
        "V2-Developer",
        "V2-Others",
      ];

      // Group members by role
      Map<String, List<Member>> grouped = {};
      for (var member in loadedMembers) {
        grouped.putIfAbsent(member.role, () => []).add(member);
      }

      // Format string
      StringBuffer descriptionBuffer = StringBuffer();
      for (String role in roleOrder) {
        if (grouped.containsKey(role)) {
          descriptionBuffer.writeln(role);
          for (var member in grouped[role]!) {
            descriptionBuffer.writeln("${member.name}");
          }
          descriptionBuffer.writeln(); // Extra line between roles
        }
      }

      setState(() {
        members = loadedMembers;

        slides.add(
          newSlide(
            imgPath: "assets/icon.png",
            discription: descriptionBuffer.toString(),
            title: "About Team",
          ),
        );

        isLoadingSlides = false;
      });
    });
  }

  void onDonePress() {
    // Back to the first tab
    Navigator.of(context).pop();
  }

  void onTabChangeCompleted(index) {
    // Index of current tab is focused
  }

  Widget renderNextBtn() {
    return Icon(
      Icons.navigate_next,
      color: color2,
      size: 25.0,
    );
  }

  Widget renderDoneBtn() {
    return Icon(
      Icons.done,
      color: color2,
    );
  }

  Widget renderSkipBtn() {
    return Icon(
      Icons.skip_next,
      color: color2,
    );
  }

  List<Widget> renderListCustomTabs() {
    List<Widget> tabs = [];
    for (int i = 0; i < slides.length; i++) {
      ContentConfig currentSlide = slides[i];
      tabs.add(Container(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          child: ListView(
            children: <Widget>[
              SizedBox(
                height: 50,
              ),
              GestureDetector(
                  child: Image.asset(
                currentSlide.pathImage!,
                width: 200.0,
                height: 200.0,
                fit: BoxFit.contain,
              )),
              Container(
                child: Text(
                  currentSlide.title!,
                  style: currentSlide.styleTitle,
                  textAlign: TextAlign.center,
                ),
                margin: EdgeInsets.only(top: 20.0, left: 20, right: 20),
              ),
              Container(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
                  child: Text(
                    currentSlide.description!,
                    style: currentSlide.styleDescription,
                    textAlign: TextAlign.center,
                  ),
                ),
                height: 300, // Optional: control scroll height inside slide
              ),
            ],
          ),
        ),
      ));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
      ),
      body: isLoadingSlides
          ? Center(child: SpinKitRotatingCircle())
          : IntroSlider(
              listContentConfig: this.slides,
              renderSkipBtn: this.renderSkipBtn(),
              renderNextBtn: this.renderNextBtn(),
              renderDoneBtn: this.renderDoneBtn(),
              skipButtonStyle:
                  ButtonStyle(backgroundColor: WidgetStateProperty.all(color5)),
              nextButtonStyle:
                  ButtonStyle(backgroundColor: WidgetStateProperty.all(color5)),
              doneButtonStyle:
                  ButtonStyle(backgroundColor: WidgetStateProperty.all(color5)),
              onDonePress: this.onDonePress,
              listCustomTabs: this.renderListCustomTabs(),
              backgroundColorAllTabs: Colors.white,
              refFuncGoToTab: (refFunc) {
                this.goToTab = refFunc;
              },
              onTabChangeCompleted: this.onTabChangeCompleted,
            ),
    );
  }
}
