// lib/core/ui/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

typedef TabSelectedCallback = void Function(int index);

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final TabSelectedCallback? onTabSelected;
  final List<GlobalKey> navKeys;

  BottomNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onTabSelected,
    List<GlobalKey>? navKeys,
  }) : navKeys = navKeys ?? List.generate(5, (_) => GlobalKey());

  // Upload removed — 5 items remaining
  static const _items = <_NavItem>[
    _NavItem(label: 'Home',       icon: Icons.home_rounded),
    _NavItem(label: 'Search',     icon: Icons.search_rounded),
    _NavItem(label: 'Scan',       icon: Icons.qr_code_scanner_rounded),
    _NavItem(label: 'Categories', icon: Icons.grid_view_rounded),
    _NavItem(label: 'Smart Read', icon: Icons.document_scanner_rounded),
  ];

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    onTabSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          14, 0, 14, bottomPadding > 0 ? bottomPadding + 4 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111E1B),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF1F3530), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF0D9E7A).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: List.generate(_items.length, (index) {
                return Expanded(
                  child: _NavTile(
                    key: navKeys[index],
                    item: _items[index],
                    selected: index == selectedIndex,
                    onTap: () => _handleTap(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _scaleAnim =
  Tween<double>(begin: 1.0, end: 0.88).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final Color iconColor  = selected ? Colors.white : const Color(0xFF3D6E63);
    final Color labelColor = selected ? Colors.white : const Color(0xFF3D6E63);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: 42,
                height: 36,
                decoration: selected
                    ? BoxDecoration(
                  color: const Color(0xFF0D9E7A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9E7A).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                )
                    : const BoxDecoration(color: Colors.transparent),
                child: Icon(widget.item.icon, size: 21, color: iconColor),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  height: 1.15,
                  color: labelColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}
