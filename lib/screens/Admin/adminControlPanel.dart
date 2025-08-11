import 'package:ephysicsapp/globals/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AdminControlPanel extends StatefulWidget {
  const AdminControlPanel({super.key});

  @override
  State<AdminControlPanel> createState() => _AdminControlPanelState();
}

class _AdminControlPanelState extends State<AdminControlPanel> {
  bool _showBranchField = false;
  bool _showDateField = false;
  bool _isLoading = true;

  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref('Departments');

  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    setState(() => _isLoading = true);

    final snapshot = await _dbRef.get();
    List<String> tempList = [];
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        tempList.add(value.toString());
      });
    }

    setState(() {
      _departments = tempList;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(today.year + 5),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showLoadingDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 50),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const SpinKitCircle(
                  color: Colors.blue,
                  size: 32,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveBranch(TextEditingController branchController) async {
    final branchName = branchController.text.trim();
    if (branchName.isEmpty) return;

    _showLoadingDialog("Saving...");
    try {
      await _dbRef.push().set(branchName);
      await Future.delayed(const Duration(seconds: 1));
      branchController.clear();
      setState(() {
        _showBranchField = false;
      });
      fetchDepartments();
    } catch (e) {
      debugPrint("Error saving branch: $e");
    } finally {
      Navigator.pop(context);
    }
  }

  Future<void> saveDate(TextEditingController dateController) async {
    final date = dateController.text.trim();
    if (date.isEmpty) return;

    _showLoadingDialog("Saving...");
    try {
      final databaseRef = FirebaseDatabase.instance.ref('Push_User_Update');
      await databaseRef.push().set(date);
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      Navigator.pop(context);
      _dateController.clear();
      setState(() {
        _showDateField = false;
      });
    }
  }

  Future<void> _deleteBranch(String branchName) async {
    bool confirm = await _showConfirmDialog(
        "Are you sure you want to delete this branch?");
    if (!confirm) return;

    _showLoadingDialog("Deleting...");
    final snapshot = await _dbRef.orderByValue().equalTo(branchName).once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      for (var key in data.keys) {
        await _dbRef.child(key).remove();
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
    fetchDepartments();
  }

  Future<void> _editBranch(String oldName) async {
    final TextEditingController editController =
    TextEditingController(text: oldName);

    bool confirm = await _showEditDialog(editController);
    if (!confirm) return;

    _showLoadingDialog("Editing...");
    final snapshot = await _dbRef.orderByValue().equalTo(oldName).once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      for (var key in data.keys) {
        await _dbRef.child(key).set(editController.text.trim());
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
    fetchDepartments();
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> _showEditDialog(TextEditingController controller) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Branch"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Branch Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildSection({
    required String title,
    required String buttonLabel,
    required VoidCallback onPressed,
    required bool isExpanded,
    required Widget expandedChild,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonLabel, style: const TextStyle(color: Colors.white)),
              )
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isExpanded
                ? Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: expandedChild,
            )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }

  Widget buildDepartmentTable() {
    final screenWidth = MediaQuery.of(context).size.width;

    final srNoWidth = screenWidth * 0.15;
    final deptNameWidth = screenWidth * 0.45;
    final actionsWidth = screenWidth * 0.25;

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: srNoWidth,
                child: const Text(
                  "Sr No.",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: deptNameWidth,
                child: const Text(
                  "Department Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: actionsWidth,
                child: const Text(
                  "Actions",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Table Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _departments.length,
          itemBuilder: (context, index) {
            final deptName = _departments[index];
            final bool isEven = index % 2 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              color: isEven ? Colors.grey[50] : Colors.grey[200],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: srNoWidth,
                    child: Center(
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF495962),
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  // Department name
                  SizedBox(
                    width: deptNameWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        deptName,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Actions
                  SizedBox(
                    width: actionsWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color:  Color(0xFF495962), size: 16),
                          onPressed: () => _editBranch(deptName),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: Color(0xFF495962), size: 16),
                          onPressed: () => _deleteBranch(deptName),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildTableShimmer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final srNoWidth = screenWidth * 0.15;
    final deptNameWidth = screenWidth * 0.35;
    final actionsWidth = screenWidth * 0.25;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: srNoWidth, child: _shimmerBox(height: 14)),
              SizedBox(width: deptNameWidth, child: _shimmerBox(height: 14)),
              SizedBox(width: actionsWidth, child: _shimmerBox(height: 14)),
            ],
          ),
        ),

        // Body shimmer rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          itemBuilder: (context, index) {
            final bool isEven = index % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: isEven ? Colors.grey[50] : Colors.grey[200],
              child: Row(
                children: [
                  SizedBox(
                    width: srNoWidth,
                    child: Center(
                      child: _shimmerCircle(size: 24),
                    ),
                  ),
                  SizedBox(
                    width: deptNameWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _shimmerBox(height: 14),
                    ),
                  ),
                  SizedBox(
                    width: actionsWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _shimmerCircle(size: 16),
                        const SizedBox(width: 8),
                        _shimmerCircle(size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _shimmerBox({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _shimmerCircle({required double size}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Control Panel", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              title: "Add new branch",
              buttonLabel: _showBranchField ? "Save" : "Add Branch",
              onPressed: () {
                if (_showBranchField) {
                  saveBranch(_branchController);
                } else {
                  setState(() => _showBranchField = true);
                }
              },
              isExpanded: _showBranchField,
              expandedChild: TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: "Branch Name",
                  hintText: "Enter branch name",
                ),
              ),
            ),
            _buildSection(
              title: "Add new update date",
              buttonLabel: _showDateField ? "Save" : "Add Date",
              onPressed: () {
                if (_showDateField) {
                  saveDate(_dateController);
                } else {
                  setState(() => _showDateField = true);
                }
              },
              isExpanded: _showDateField,
              expandedChild: GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: "Update Date",
                      hintText: "Select a future date",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading ? buildTableShimmer() : buildDepartmentTable(),
          ],
        ),
      ),
    );
  }
}
