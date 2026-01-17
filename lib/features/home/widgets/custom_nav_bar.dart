import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    double displayWidth = MediaQuery.of(context).size.width;
    double navBarWidth = displayWidth - 40; // Horizontal padding 20 * 2
    double itemWidth = navBarWidth / 4;
    double bubbleWidth = 50.0;
    double bubbleHeight = 50.0;

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Moving Bubble
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack,
            right:
                (homeProvider.selectedIndex * itemWidth) +
                (itemWidth - bubbleWidth) / 2,
            top: (65 - bubbleHeight) / 2,
            child: Container(
              width: bubbleWidth,
              height: bubbleHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39BB5E).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          // Icons Layer
          Row(
            children: [
              _navItem(context, Icons.home_rounded, 0, itemWidth),
              _navItem(context, Icons.search, 1, itemWidth),
              _navItem(context, Icons.chat_bubble_outline, 2, itemWidth),
              _navItem(context, Icons.person_outline, 3, itemWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    int index,
    double width,
  ) {
    final homeProvider = context.read<HomeProvider>();
    // We can use read here because the parent checks the index for the bubble,
    // and we want onTap to trigger the change.
    // However, to change the icon color, we need to know the selected index.
    // The parent 'build' watches HomeProvider, so this widget rebuilds when it changes.
    // But strictly locally, we need access to the selected index for the color.
    // Since we are inside the build method that watches, specific logic for color needs current index.
    final selectedIndex = context.watch<HomeProvider>().selectedIndex;
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => homeProvider.setIndex(index),
      child: Container(
        width: width,
        height: 65,
        color: Colors.transparent, // Hit test behavior
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }
}
