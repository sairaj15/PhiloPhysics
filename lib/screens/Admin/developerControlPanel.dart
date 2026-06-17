import 'package:ephysicsapp/globals/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shimmer/shimmer.dart';

class DeveloperControlPanel extends StatefulWidget {
  const DeveloperControlPanel({Key? key}) : super(key: key);

  @override
  State<DeveloperControlPanel> createState() => _DeveloperControlPanelState();
}

class _DeveloperControlPanelState extends State<DeveloperControlPanel> {
  final dbRef = FirebaseDatabase.instance.ref("AppGlobalSettings");

  bool isLoading = true;
  bool forceUpdate = false;
  bool maintenanceMode = false;
  String androidVersion = "0.0.0";
  String iosVersion = "0.0.0";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Widget _buildShimmerTile(BuildContext context,
      {bool hasSwitch = false,
      bool hasTrailingText = false,
      required int index}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double titleWidth = index.isEven ? screenWidth * 0.35 : screenWidth * 0.5;

    return Container(
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: screenWidth * 0.06,
            width: titleWidth,
            color: Colors.white,
          ),
          if (hasSwitch)
            Container(
              height: screenWidth * 0.06,
              width: screenWidth * 0.1,
              color: Colors.white,
            ),
          if (hasTrailingText)
            Container(
              height: screenWidth * 0.06,
              width: screenWidth * 0.15,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget buildShimmerRow(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          _buildShimmerTile(context, hasSwitch: true, index: 0),
          _buildShimmerTile(context, hasSwitch: true, index: 1),
          _buildShimmerTile(context, hasTrailingText: true, index: 2),
          _buildShimmerTile(context, hasTrailingText: true, index: 3),
        ],
      ),
    );
  }

  Widget buildSettingsList(
      bool forceUpdate,
      bool maintenanceMode,
      String androidVersion,
      String iosVersion,
      Function(String, String, bool) confirmSwitchChange,
      Function(String, String) editVersion) {
    final Color tileColor = color5.withValues(alpha: 0.2);

    final List<Map<String, dynamic>> settings = [
      {
        'title': 'Enable Force Update',
        'trailing': (context) => Transform.scale(
              scale: 0.85,
              child: Switch(
                value: forceUpdate,
                onChanged: (_) => confirmSwitchChange(
                    "Force Update", "forceUpdate", forceUpdate),
              ),
            ),
      },
      {
        'title': 'Enable Maintenance Mode',
        'trailing': (context) => Transform.scale(
              scale: 0.85,
              child: Switch(
                value: maintenanceMode,
                onChanged: (_) => confirmSwitchChange(
                    "Maintenance Mode", "maintainanceMode", maintenanceMode),
              ),
            ),
      },
      {
        'title': 'Android App Version',
        'trailing': (context) => GestureDetector(
              onTap: () => editVersion("android_Version", androidVersion),
              child: Text(
                androidVersion,
                style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
      },
      {
        'title': 'iOS App Version',
        'trailing': (context) => GestureDetector(
              onTap: () => editVersion("ios_Version", iosVersion),
              child: Text(
                iosVersion,
                style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
      },
    ];

    return ListView.builder(
      itemCount: settings.length,
      itemBuilder: (context, index) {
        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  settings[index]['title'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              settings[index]['trailing'](context),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        forceUpdate = data["forceUpdate"] ?? false;
        maintenanceMode = data["maintainanceMode"] ?? false;
        androidVersion = data["android_Version"] ?? "0.0.0";
        iosVersion = data["ios_Version"] ?? "0.0.0";
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }

    void _showSmallLoading(String text) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder: (context) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(
                bottom: screenHeight * 0.03,
                left: screenWidth * 0.25,
                right: screenWidth * 0.25,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinKitCircle(color: Colors.blue, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Future<void> updateField(String field, dynamic value) async {
      _showSmallLoading("Saving...");
      try {
        await dbRef.update({field: value});
        await fetchData();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // remove loading dialog
        }
      } catch (e) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to update, please try again")),
        );
      }
    }

    Future<void> confirmSwitchChange(
        String title, String field, bool currentValue) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Confirm Change"),
          content: Text(
              "Are you sure you want to ${currentValue ? 'switch from ON to OFF' : 'switch from OFF to ON'} the $title?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        updateField(field, !currentValue);
      }
    }

    Future<void> editVersion(String field, String currentVersion) async {
      List<int> parts =
          currentVersion.split(".").map((e) => int.tryParse(e) ?? 0).toList();
      int major = parts[0], minor = parts[1], patch = parts[2];
      bool changed = false;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) {
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: StatefulBuilder(
              builder: (context, setStateSB) {
                void checkChanged() {
                  String newV = "$major.$minor.$patch";
                  setStateSB(() {
                    changed = newV != currentVersion;
                  });
                }

                Widget buildModernPickerBox({
                  required int value,
                  required ValueChanged<int> onChanged,
                  required String label,
                }) {
                  return Column(
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.3)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(2, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.black12),
                        ),
                        child: NumberPicker(
                          value: value,
                          minValue: 0,
                          maxValue: 99,
                          onChanged: (v) {
                            onChanged(v);
                            checkChanged();
                          },
                          textStyle: const TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.w400),
                          selectedTextStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          itemHeight: 45,
                          itemWidth: 45,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.black12),
                              bottom: BorderSide(color: Colors.black12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Edit Version",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(
                                    "Change the app version of '$field' to the latest version",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context, false),
                            child: Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildModernPickerBox(
                              value: major,
                              onChanged: (v) => major = v,
                              label: "Major"),
                          buildModernPickerBox(
                              value: minor,
                              onChanged: (v) => minor = v,
                              label: "Minor"),
                          buildModernPickerBox(
                              value: patch,
                              onChanged: (v) => patch = v,
                              label: "Patch"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel")),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                disabledBackgroundColor:
                                    Colors.blue.withValues(alpha: 0.5)),
                            onPressed: changed
                                ? () => Navigator.pop(context, true)
                                : null,
                            child: const Text("Confirm",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );

      if (confirm == true) {
        String newVersion = "$major.$minor.$patch";
        updateField(field, newVersion);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Developer Control Panel",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          child: isLoading
              ? buildShimmerRow(context)
              : buildSettingsList(forceUpdate, maintenanceMode, androidVersion,
                  iosVersion, confirmSwitchChange, editVersion),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Control Panel",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // body: Padding(
      //   padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      //   child: isLoading
      //       ? buildShimmerRow(context)
      //       : buildSettingsList(forceUpdate, maintenanceMode, androidVersion,
      //           iosVersion, confirmSwitchChange, editVersion),
      // ),
    );
  }
}
