import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme_mode_controller.dart';
import '../../core/providers.dart';
import '../auth/providers/auth_controller.dart';
import '../notifications/notification_bell.dart';

class _NavItem {
  final String path;
  final String label;
  final IconData icon;

  const _NavItem(this.path, this.label, this.icon);
}

const _navItems = [
  _NavItem('/dashboard', 'Dashboard', Icons.dashboard_outlined),
  _NavItem('/tracking', 'Tracking', Icons.checklist_outlined),
  _NavItem('/exercises', 'Exercises', Icons.fitness_center_outlined),
  _NavItem('/expenses', 'Expenses', Icons.account_balance_wallet_outlined),
  _NavItem('/diet-suggestion', 'Diet Plan', Icons.restaurant_menu_outlined),
  _NavItem('/food-recommendation', 'Cook This', Icons.soup_kitchen_outlined),
  _NavItem('/social', 'Social', Icons.people_outline),
  _NavItem('/settings', 'Settings', Icons.settings_outlined),
];

/// Phone-width bottom bar only shows these three directly — everything else
/// (including the trailing "More" sheet contents) lives in [_moreNavItems].
const _primaryNavItems = [
  _NavItem('/dashboard', 'Dashboard', Icons.dashboard_outlined),
  _NavItem('/tracking', 'Tracking', Icons.checklist_outlined),
  _NavItem('/exercises', 'Exercises', Icons.fitness_center_outlined),
];

const _moreNavItems = [
  _NavItem('/expenses', 'Expenses', Icons.account_balance_wallet_outlined),
  _NavItem('/diet-suggestion', 'Diet Plan', Icons.restaurant_menu_outlined),
  _NavItem('/food-recommendation', 'Cook This', Icons.soup_kitchen_outlined),
  _NavItem('/social', 'Social', Icons.people_outline),
  _NavItem('/settings', 'Settings', Icons.settings_outlined),
];

class HomeShell extends ConsumerWidget {
  final Widget child;

  const HomeShell({required this.child, super.key});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _navItems.indexWhere(
      (item) => location.startsWith(item.path),
    );
    return index == -1 ? 0 : index;
  }

  /// Index into [_primaryNavItems], or -1 when the current route lives under
  /// "More" instead — the bottom bar then highlights the More tab itself.
  int _primaryIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return _primaryNavItems.indexWhere(
      (item) => location.startsWith(item.path),
    );
  }

  Future<void> _showMoreSheet(BuildContext context) async {
    final location = GoRouterState.of(context).matchedLocation;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in _moreNavItems)
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: location.startsWith(item.path),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      sheetContext.go(item.path);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final currentIndex = _currentIndex(context);
    final primaryIndex = _primaryIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeToggle = IconButton(
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed:
          () => ref
              .read(themeModeProvider.notifier)
              .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );

    final destinations =
        _navItems
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              ),
            )
            .toList();

    return Scaffold(
      appBar:
          isWide
              ? null
              : AppBar(
                title: const Text('Fitness Buddy'),
                actions: [
                  const NotificationBell(),
                  themeToggle,
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                    onPressed:
                        () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
      body:
          isWide
              ? Column(
                children: [
                  Material(
                    elevation: 1,
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            'Fitness Buddy',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          const NotificationBell(),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // NavigationRail doesn't scroll on its own — with 8
                        // destinations plus the leading avatar/buttons, it
                        // can be taller than the viewport on shorter windows
                        // and overflow. Wrapping it this way (the pattern
                        // NavigationRail's own docs recommend) lets it
                        // scroll instead.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: NavigationRail(
                                    selectedIndex: currentIndex,
                                    onDestinationSelected:
                                        (i) => context.go(_navItems[i].path),
                                    labelType: NavigationRailLabelType.all,
                                    leading: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 12),
                                        CircleAvatar(
                                          child: Text(
                                            (profile?.displayName.isNotEmpty ??
                                                    false)
                                                ? profile!.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        themeToggle,
                                        IconButton(
                                          icon: const Icon(Icons.logout),
                                          tooltip: 'Sign out',
                                          onPressed:
                                              () =>
                                                  ref
                                                      .read(
                                                        authControllerProvider
                                                            .notifier,
                                                      )
                                                      .signOut(),
                                        ),
                                      ],
                                    ),
                                    destinations: destinations,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              )
              : child,
      bottomNavigationBar:
          isWide
              ? null
              : NavigationBar(
                selectedIndex:
                    primaryIndex == -1 ? _primaryNavItems.length : primaryIndex,
                onDestinationSelected: (i) {
                  if (i == _primaryNavItems.length) {
                    _showMoreSheet(context);
                  } else {
                    context.go(_primaryNavItems[i].path);
                  }
                },
                destinations: [
                  for (final item in _primaryNavItems)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  const NavigationDestination(
                    icon: Icon(Icons.more_horiz),
                    label: 'More',
                  ),
                ],
              ),
    );
  }
}
