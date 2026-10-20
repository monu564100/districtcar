import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'admin_sidebar.dart';

class AdminScaffold extends StatelessWidget {
  final String activeRoute;
  final Widget body;
  final String title;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.activeRoute,
    required this.body,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            AdminSidebar(activeRoute: activeRoute),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Responsive Mobile / Tablet Layout
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2030),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Open Menu',
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (actions != null) ...actions!,
          IconButton(
            tooltip: 'Lock Console',
            icon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.go('/admin-login'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        width: 270,
        backgroundColor: const Color(0xFF1B2030),
        child: SafeArea(
          child: AdminSidebar(activeRoute: activeRoute),
        ),
      ),
      body: body,
    );
  }
}
