import 'package:ephysicsapp/main.dart';
import 'package:ephysicsapp/screens/users/studentLogin.dart';
import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class ProfileSidebarDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;
  final bool isStudent;
  final VoidCallback onLogout;
  final VoidCallback onLogin;
  final VoidCallback onAdminLogin;
  final VoidCallback onQuery;
  final VoidCallback onAdminStats;

  const ProfileSidebarDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isAdmin,
    required this.isStudent,
    required this.onLogout,
    required this.onLogin,
    required this.onAdminLogin,
    required this.onQuery,
    required this.onAdminStats,
  }) : super(key: key);

  @override
  State<ProfileSidebarDrawer> createState() => _ProfileSidebarDrawerState();
}

class _ProfileSidebarDrawerState extends State<ProfileSidebarDrawer> {
  String? userName;
  String? userEmail;
  String? userClassDiv;
  bool _isLoading = true;

  bool get isLoggedIn => widget.isAdmin || widget.isStudent;

  @override
  void initState() {
    super.initState();
    if (isLoggedIn) {
      _loadUserDataFromPrefs();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      userName = prefs.getString('name') ?? '';
      userEmail = prefs.getString('email') ?? '';
      userClassDiv = prefs.getString('classDiv') ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String avatarSeed = userName ?? 'User';
    final Color selectedColor = const Color(0xFFE6E6E6);

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: _isLoading
            ? _SidebarSkeletonLoader()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Profile Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : isLoggedIn
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.purple[100],
                                    ),
                                    child: ClipOval(
                                      child: RandomAvatar(
                                        avatarSeed,
                                        trBackground: true,
                                        height: 70,
                                        width: 70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    userName ?? 'No Name',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  if (userClassDiv != null &&
                                      userClassDiv!.isNotEmpty)
                                    Text(
                                      userClassDiv!,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  if (userEmail != null &&
                                      userEmail!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        userEmail!,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  const Divider(
                                      thickness: 1, color: Color(0xFFE0E0E0)),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.purple[100],
                                    ),
                                    child: const Icon(Icons.person,
                                        size: 40, color: Colors.white),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Welcome User!",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Please log in to continue",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(
                                      thickness: 1, color: Color(0xFFE0E0E0)),
                                ],
                              ),
                  ),
                  const SizedBox(height: 10),

                  // Menu Items (unchanged, use your logic here)
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SidebarItem(
                          icon: Icons.home_rounded,
                          label: "Home",
                          isSelected: widget.selectedIndex == 0,
                          selectedColor: selectedColor,
                          onTap: () {
                            widget.onItemSelected(0);
                            Navigator.of(context).pop();
                          },
                        ),
                        SidebarItem(
                          icon: Icons.book_rounded,
                          label: "Notes",
                          isSelected: widget.selectedIndex == 1,
                          selectedColor: selectedColor,
                          onTap: () {
                            widget.onItemSelected(1);
                            Navigator.of(context).pop();
                          },
                        ),
                        SidebarItem(
                          icon: Icons.timer,
                          label: "Quizzes",
                          isSelected: widget.selectedIndex == 2,
                          selectedColor: selectedColor,
                          onTap: () {
                            widget.onItemSelected(2);
                            Navigator.of(context).pop();
                          },
                        ),
                        SidebarItem(
                          icon: Icons.science_rounded,
                          label: "V-Labs",
                          isSelected: widget.selectedIndex == 3,
                          selectedColor: selectedColor,
                          onTap: () {
                            widget.onItemSelected(3);
                            Navigator.of(context).pop();
                          },
                        ),
                        if (widget.isAdmin)
                          SidebarItem(
                            icon: Icons.insights,
                            label: "Admin Statistics",
                            isSelected: false,
                            selectedColor: selectedColor,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onAdminStats();
                            },
                          ),
                        if (widget.isAdmin || widget.isStudent)
                          SidebarItem(
                            icon: Icons.bug_report,
                            label: "Raise a bug / Query",
                            isSelected: false,
                            selectedColor: selectedColor,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onQuery();
                            },
                          ),
                      ],
                    ),
                  ),

                  // Login/Logout Button at the Bottom
                  if (isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onLogout();
                        },
                      ),
                    ),
                  if (!isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Builder(
                        builder: (context) => ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green[700],
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.login, color: Colors.green),
                          label: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 250),
                                () {
                              navigatorKey.currentState?.push(
                                MaterialPageRoute(
                                    builder: (context) => StudentLogin()),
                              );
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color? selectedColor;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const SidebarItem({
    Key? key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.selectedColor,
    required this.onTap,
    this.iconColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: ListTile(
          horizontalTitleGap: 10,
          leading: Icon(icon, color: iconColor ?? Colors.black),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textColor ?? Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SidebarSkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Menu items
          ...List.generate(
              5,
              (index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 120,
                          height: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  )),
          const Spacer(),
          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
