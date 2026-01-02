import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeveloperControlPanel extends StatefulWidget {
  const DeveloperControlPanel({super.key});

  @override
  State<DeveloperControlPanel> createState() => _DeveloperControlPanelState();
}

class _DeveloperControlPanelState extends State<DeveloperControlPanel> {
  bool _forceUpdate = false;
  bool _isLoading = true;
  final DatabaseReference _configRef =
      FirebaseDatabase.instance.ref('AppConfig');

  @override
  void initState() {
    super.initState();
    _fetchForceUpdate();
  }

  Future<void> _fetchForceUpdate() async {
    setState(() => _isLoading = true);
    final snapshot = await _configRef.child('force_update').get();
    setState(() {
      _forceUpdate = snapshot.value == true;
      _isLoading = false;
    });
  }

  Future<void> _setForceUpdate(bool value) async {
    setState(() => _isLoading = true);
    await _configRef.child('force_update').set(value);
    setState(() {
      _forceUpdate = value;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Control Panel",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: const Text("Force Update"),
                      subtitle: const Text(
                          "If enabled, users will be forced to update the app after every new update."),
                      trailing: Switch(
                        value: _forceUpdate,
                        onChanged: (val) => _setForceUpdate(val),
                        activeThumbColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Current Status: ${_forceUpdate ? "Force Update ON" : "Force Update OFF"}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
