// import 'package:flutter/material.dart';

// import '../../trips/presentation/widgets/custom_app_bar.dart';

// /// A reusable bottom navigation widget that can adapt to different numbers of navigation items.
// class CustomBottomNavigation extends StatelessWidget {
//   /// The current selected index
//   final int currentIndex;

//   /// Callback function when a navigation item is tapped
//   final Function(int) onTap;

//   /// List of navigation items to display
//   final List<BottomNavigationBarItem> items;

//   /// Color for the selected item
//   final Color? selectedItemColor;

//   /// Color for unselected items
//   final Color? unselectedItemColor;

//   /// Background color of the navigation bar
//   final Color? backgroundColor;

//   /// Type of the bottom navigation bar
//   final BottomNavigationBarType type;

//   /// Elevation of the navigation bar
//   final double elevation;

//   const CustomBottomNavigation({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     required this.items,
//     this.selectedItemColor,
//     this.unselectedItemColor,
//     this.backgroundColor,
//     this.type = BottomNavigationBarType.fixed,
//     this.elevation = 8.0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: onTap,
//       items: items,
//       selectedItemColor: selectedItemColor ?? theme.primaryColor,
//       unselectedItemColor: unselectedItemColor ?? Colors.grey[600],
//       backgroundColor: backgroundColor,
//       type: type,
//       elevation: elevation,
//     );
//   }
// }

// /// A model class to represent navigation item data
// class NavigationItemData {
//   final IconData icon;
//   final String label;
//   final Widget? screen;

//   const NavigationItemData({
//     required this.icon,
//     required this.label,
//     this.screen,
//   });

//   BottomNavigationBarItem toBottomNavigationBarItem() {
//     return BottomNavigationBarItem(
//       icon: Icon(icon),
//       label: label,
//     );
//   }
// }

// /// A widget that combines the bottom navigation with the page content
// class NavigationContainer extends StatefulWidget {
//   /// List of navigation item data
//   final List<NavigationItemData> items;

//   /// Initial selected index
//   final int initialIndex;

//   /// Callback when index changes
//   final Function(int)? onIndexChanged;

//   /// Color for the selected item
//   final Color? selectedItemColor;

//   /// Color for unselected items
//   final Color? unselectedItemColor;

//   /// Background color of the navigation bar
//   final Color? backgroundColor;

//   /// Type of the bottom navigation bar
//   final BottomNavigationBarType type;

//   /// Elevation of the navigation bar
//   final double elevation;

//   const NavigationContainer({
//     super.key,
//     required this.items,
//     this.initialIndex = 0,
//     this.onIndexChanged,
//     this.selectedItemColor,
//     this.unselectedItemColor,
//     this.backgroundColor,
//     this.type = BottomNavigationBarType.fixed,
//     this.elevation = 8.0,
//   });

//   @override
//   State<NavigationContainer> createState() => _NavigationContainerState();
// }

// class _NavigationContainerState extends State<NavigationContainer> {
//   late int _currentIndex;

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//   }

//   @override
//   void didUpdateWidget(NavigationContainer oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Update current index if initialIndex changes
//     if (widget.initialIndex != oldWidget.initialIndex) {
//       _currentIndex = widget.initialIndex;
//     }
//   }

//   void _onTap(int index) {
//     if (index != _currentIndex) {
//       setState(() {
//         _currentIndex = index;
//       });

//       // Call the callback if provided
//       if (widget.onIndexChanged != null) {
//         widget.onIndexChanged!(index);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Convert NavigationItemData to BottomNavigationBarItem
//     final navItems = widget.items.map((item) => item.toBottomNavigationBarItem()).toList();

//     // Get the current screen to display
//     final currentScreen = widget.items[_currentIndex].screen ?? Container();

//     return Scaffold(
//       appBar: const CustomUserAppBar(),
//       body: currentScreen,
//       bottomNavigationBar: CustomBottomNavigation(
//         currentIndex: _currentIndex,
//         onTap: _onTap,
//         items: navItems,
//         selectedItemColor: widget.selectedItemColor,
//         unselectedItemColor: widget.unselectedItemColor,
//         backgroundColor: widget.backgroundColor,
//         type: widget.type,
//         elevation: widget.elevation,
//       ),
//     );
//   }
// }
