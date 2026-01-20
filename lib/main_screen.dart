import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  // 🔑 pass this in from your user state
  const MainScreen({super.key, required this.child});

  // Single source of truth for tabs
  List<_NavItem> _buildNavItems() {
    final items = <_NavItem>[
      const _NavItem(path: '/home', label: 'Home', icon: Icons.home_rounded),
      const _NavItem(
        path: '/guest-list',
        label: 'Guest List',
        icon: Icons.admin_panel_settings_rounded,
      ),
      const _NavItem(
        path: '/invite',
        label: 'Invites',
        icon: Icons.insert_invitation_rounded,
      ),
      const _NavItem(
        path: '/profile',
        label: 'Profile',
        icon: Icons.person_rounded,
      ),
    ];

    return items;
  }

  int _locationToIndex(String location, List<_NavItem> items) {
    // match by startsWith so nested routes like /profile/edit work
    final i = items.indexWhere((e) => location.startsWith(e.path));
    return i == -1 ? 0 : i;
  }

  void _onItemTapped(BuildContext context, int index, List<_NavItem> items) {
    context.go(items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNavItems();
    final loc = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(loc, items);

    return Scaffold(
      backgroundColor: Colors.black,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.yellow,
        selectedItemColor: Colors.pink,
        showUnselectedLabels: true,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: (i) => _onItemTapped(context, i, items),
        items: [
          for (final e in items)
            BottomNavigationBarItem(icon: Icon(e.icon), label: e.label),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  const _NavItem({required this.path, required this.label, required this.icon});
}
