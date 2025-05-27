import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final List<String> usernames;

  const TypingIndicator({
    super.key,
    required this.usernames,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usernames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey[300],
            child: Text(
              widget.usernames.first[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTypingText(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Row(
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final animationValue = (_animation.value - delay).clamp(0.0, 1.0);
                          final opacity = (animationValue * 2).clamp(0.0, 1.0);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypingText() {
    if (widget.usernames.length == 1) {
      return '${widget.usernames.first} is typing';
    } else if (widget.usernames.length == 2) {
      return '${widget.usernames.first} and ${widget.usernames.last} are typing';
    } else {
      return '${widget.usernames.first} and ${widget.usernames.length - 1} others are typing';
    }
  }
}
