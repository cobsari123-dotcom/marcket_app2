import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatefulWidget {
  final List<Widget> pages;
  final Drawer drawer;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget? appBarTitle; // New property for AppBar title
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.pages,
    required this.drawer,
    required this.initialIndex,
    required this.onIndexChanged,
    this.appBarTitle, // Initialize new property
    this.appBarActions,
    this.floatingActionButton,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.initialIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Narrow layout (mobile)
          return Scaffold(
            appBar: AppBar( // AppBar for narrow layout
              title: widget.appBarTitle,
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  );
                }
              ),
              actions: widget.appBarActions,
            ),
            drawer: widget.drawer,
            body: widget.pages[selectedIndex],
            floatingActionButton: widget.floatingActionButton,
          );
        } else {
          // Wide layout (desktop/tablet)
          return Scaffold(
            body: Row(
              children: [
                widget.drawer,
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: widget.pages[selectedIndex],
                ),
              ],
            ),
            floatingActionButton: widget.floatingActionButton,
          );
        }
      },
    );
  }
}
