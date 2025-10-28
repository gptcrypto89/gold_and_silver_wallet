import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated Floating Action Button with smooth transitions
class AnimatedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final bool isVisible;
  final Duration animationDuration;
  final Curve animationCurve;
  final String? heroTag;

  const AnimatedFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.isVisible = true,
    this.animationDuration = AppTheme.mediumDuration,
    this.animationCurve = Curves.easeInOut,
    this.heroTag,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    _widthAnimation = Tween<double>(
      begin: 56.0,
      end: 200.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.0, 1.0),
            child: widget.isExtended
                ? SizedBox(
                    width: _widthAnimation.value.clamp(56.0, 200.0),
                    child: FloatingActionButton.extended(
                      onPressed: widget.onPressed,
                      backgroundColor: widget.backgroundColor ?? colorScheme.primary,
                      foregroundColor: widget.foregroundColor ?? colorScheme.onPrimary,
                      icon: Icon(widget.icon),
                      label: Text(widget.label ?? ''),
                      heroTag: widget.heroTag ?? 'fab_${widget.label ?? widget.icon.codePoint}_${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  )
                : FloatingActionButton(
                    onPressed: widget.onPressed,
                    backgroundColor: widget.backgroundColor ?? colorScheme.primary,
                    foregroundColor: widget.foregroundColor ?? colorScheme.onPrimary,
                    child: Icon(widget.icon),
                    heroTag: widget.heroTag ?? 'fab_${widget.label ?? widget.icon.codePoint}_${DateTime.now().millisecondsSinceEpoch}',
                  ),
          ),
        );
      },
    );
  }
}

/// Multiple FABs with staggered animation
class StaggeredFABs extends StatefulWidget {
  final List<FABItem> items;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Duration staggerDelay;
  final Duration animationDuration;

  const StaggeredFABs({
    super.key,
    required this.items,
    this.isExpanded = false,
    this.onToggle,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = AppTheme.mediumDuration,
  });

  @override
  State<StaggeredFABs> createState() => _StaggeredFABsState();
}

class _StaggeredFABsState extends State<StaggeredFABs>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _itemControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isExpanded) {
      _expand();
    }
  }

  @override
  void didUpdateWidget(StaggeredFABs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expand();
      } else {
        _collapse();
      }
    }
  }

  void _expand() {
    _mainController.forward();
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * widget.staggerDelay.inMilliseconds),
        () {
          if (mounted) {
            _itemControllers[i].forward();
          }
        },
      );
    }
  }

  void _collapse() {
    for (int i = _itemControllers.length - 1; i >= 0; i--) {
      Future.delayed(
        Duration(milliseconds: (widget.items.length - 1 - i) * widget.staggerDelay.inMilliseconds),
        () {
          if (mounted) {
            _itemControllers[i].reverse();
          }
        },
      );
    }
    _mainController.reverse();
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Item FABs
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return AnimatedBuilder(
            animation: _itemAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _itemAnimations[index].value.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: _itemAnimations[index].value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: item.isExtended
                        ? FloatingActionButton.extended(
                            onPressed: item.onPressed,
                            backgroundColor: item.backgroundColor,
                            foregroundColor: item.foregroundColor,
                            icon: Icon(item.icon),
                            label: Text(item.label ?? ''),
                            heroTag: 'staggered_item_${index}_${item.label ?? item.icon.codePoint}_${DateTime.now().millisecondsSinceEpoch}',
                          )
                        : FloatingActionButton(
                            onPressed: item.onPressed,
                            backgroundColor: item.backgroundColor,
                            foregroundColor: item.foregroundColor,
                            child: Icon(item.icon),
                            heroTag: 'staggered_item_${index}_${item.label ?? item.icon.codePoint}_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                  ),
                ),
              );
            },
          );
        }),
        // Main toggle FAB
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Transform.rotate(
              angle: (_mainController.value * 0.5 * 3.14159).clamp(0.0, 0.5 * 3.14159), // 90 degrees
              child: FloatingActionButton(
                onPressed: widget.onToggle,
                child: Icon(
                  widget.isExpanded ? Icons.close : Icons.add,
                ),
                heroTag: 'staggered_main_fab_${DateTime.now().millisecondsSinceEpoch}',
              ),
            );
          },
        ),
      ],
    );
  }
}

/// FAB item data class
class FABItem {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;

  const FABItem({
    this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
  });
}

/// Speed dial FAB with multiple options
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialItem> items;
  final IconData mainIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const SpeedDialFAB({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.mediumDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speed dial items
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.label != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space12,
                              vertical: AppTheme.space8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radius8),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Text(
                              item.label!,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                        ],
                        FloatingActionButton(
                          onPressed: item.onPressed,
                          backgroundColor: item.backgroundColor ?? colorScheme.secondary,
                          foregroundColor: item.foregroundColor ?? colorScheme.onSecondary,
                          mini: true,
                          child: Icon(item.icon),
                          heroTag: 'speed_dial_item_${index}_${item.label ?? item.icon.codePoint}_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: (_rotationAnimation.value * 2 * 3.14159).clamp(0.0, 2 * 3.14159),
              child: FloatingActionButton(
                onPressed: _toggle,
                backgroundColor: widget.backgroundColor ?? colorScheme.primary,
                foregroundColor: widget.foregroundColor ?? colorScheme.onPrimary,
                tooltip: widget.tooltip,
                child: Icon(widget.mainIcon),
                heroTag: 'speed_dial_main_${DateTime.now().millisecondsSinceEpoch}',
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Speed dial item data class
class SpeedDialItem {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialItem({
    this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });
}
