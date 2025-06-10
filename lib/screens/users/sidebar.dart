// lib/widgets/profile_sidebar.dart
import 'package:flutter/material.dart';

class ProfileSidebarDrawer extends StatelessWidget {
  const ProfileSidebarDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F8FA),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Profile Picture
            const CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/women/44.jpg',
              ),
            ),
            const SizedBox(height: 20),
            // Name
            const Text(
              'Sophia Rose',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45),
              ),
            ),
            const SizedBox(height: 4),
            // Title
            const Text(
              'UX/UI Designer',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8F9BB3),
              ),
            ),
            const SizedBox(height: 32),
            // Menu
            Expanded(
              child: ListView(
                children: const [
                  _SidebarMenuItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: false,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.topic_rounded,
                    label: 'Topics',
                    selected: true,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.message_rounded,
                    label: 'Messages',
                    selected: false,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    selected: false,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Bookmarks',
                    selected: false,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _SidebarMenuItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: selected
          ? BoxDecoration(
              color: const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? const Color(0xFF3366FF) : const Color(0xFF8F9BB3),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF3366FF) : const Color(0xFF222B45),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onTap: () {},
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
