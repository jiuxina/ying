import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// 可展开的FAB菜单组件（垂直布局）
/// 主按钮点击后展开显示多个子按钮
class ExpandableFab extends StatefulWidget {
  final List<ExpandableFabItem> items;
  final IconData mainIcon;
  final IconData closeIcon;
  final double distance;

  const ExpandableFab({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.closeIcon = Icons.close,
    this.distance = 112,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // 使用 Curves.easeOutCubic 替代 easeOutBack，避免值超出 0-1 范围
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56 + widget.distance,
      height: 56 + widget.distance * widget.items.length * 0.8,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // 遮罩层
          if (_isOpen)
            Positioned.fill(
              right: -100,
              bottom: -100,
              child: GestureDetector(
                onTap: _close,
                child: Container(color: Colors.transparent),
              ),
            ),
          // 子按钮
          ..._buildExpandingButtons(),
          // 主按钮
          _buildMainButton(),
        ],
      ),
    );
  }

  List<Widget> _buildExpandingButtons() {
    final children = <Widget>[];
    final count = widget.items.length;
    
    for (var i = 0; i < count; i++) {
      final item = widget.items[i];
      final double offset = (i + 1) * 64.0;
      
      children.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            // 确保值在 0.0-1.0 范围内
            final animValue = _expandAnimation.value.clamp(0.0, 1.0);
            return Positioned(
              right: 0,
              bottom: offset * animValue,
              child: Transform.scale(
                scale: animValue,
                child: Opacity(
                  opacity: animValue,
                  child: child,
                ),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标签
              if (item.label != null)
                AnimatedOpacity(
                  opacity: _isOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.label!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // 按钮
              _ExpandableFabButton(
                icon: item.icon,
                color: item.color ?? Theme.of(context).colorScheme.secondary,
                onPressed: () {
                  _close();
                  item.onPressed?.call();
                },
              ),
            ],
          ),
        ),
      );
    }
    
    return children;
  }

  Widget _buildMainButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value.clamp(0.0, 1.0) * math.pi / 4,
                  child: Icon(
                    _isOpen ? widget.closeIcon : widget.mainIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableFabButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ExpandableFabButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// FAB项目数据类
class ExpandableFabItem {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onPressed;

  const ExpandableFabItem({
    required this.icon,
    this.label,
    this.color,
    this.onPressed,
  });
}
