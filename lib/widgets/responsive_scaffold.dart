import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatefulWidget {
  final List<Widget> pages;
  final List<String> titles;
  final List<NavigationRailDestination> destinations;
  final Drawer drawer;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;
  final List<Widget>? appBarActions;

  const ResponsiveScaffold({
    super.key,
    required this.pages,
    required this.titles,
    required this.destinations,
    required this.drawer,
    required this.initialIndex,
    required this.onIndexChanged,
    this.appBarActions,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant ResponsiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Narrow layout (mobile)
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.titles[_selectedIndex]),
              actions: widget.appBarActions,
            ),
            drawer: widget.drawer,
            body: widget.pages[_selectedIndex],
          );
        } else {
          // Wide layout (desktop/tablet)
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.titles[_selectedIndex]),
              actions: widget.appBarActions,
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    widget.onIndexChanged(index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: widget.destinations,
                  extended: constraints.maxWidth > 1200,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: widget.pages[_selectedIndex],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
