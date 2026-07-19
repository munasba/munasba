import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps every top-level destination in a shared bottom navigation bar with
/// a docked center FAB for quick-adding a person / event / task, matching
/// the navigation pattern described in the build plan (see plan doc, §6):
/// المهام والتقارير تُفتحان من داخل السياق بدل تبويب سفلي دائم لتفادي الازدحام.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = ['/home', '/people', '/events', '/settings'];

  int _indexForLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, icon: Icons.home_rounded, label: 'الرئيسية', index: 0, current: currentIndex),
            _navItem(context, icon: Icons.people_alt_rounded, label: 'الأشخاص', index: 1, current: currentIndex),
            const SizedBox(width: 40), // مساحة للـ FAB المركزي
            _navItem(context, icon: Icons.event_rounded, label: 'المناسبات', index: 2, current: currentIndex),
            _navItem(context, icon: Icons.settings_rounded, label: 'الإعدادات', index: 3, current: currentIndex),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context,
      {required IconData icon, required String label, required int index, required int current}) {
    final active = index == current;
    final color = active ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: () => context.go(_tabs[index]),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(color: color, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('إضافة شخص'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/people/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('إضافة مناسبة'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/events/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('إضافة مهمة'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/tasks');
              },
            ),
          ],
        ),
      ),
    );
  }
}
