import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String productName;
  final double height;
  final double width;
  final double borderRadius;

  const ProductImage({
    super.key,
    this.imageUrl,
    required this.productName,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  static final _gradients = <List<Color>>[
    [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
    [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
    [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
    [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
    [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
    [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
    [const Color(0xFFFBE9E7), const Color(0xFFFFCCBC)],
    [const Color(0xFFF1F8E9), const Color(0xFFDCEDC8)],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hash = productName.hashCode.abs();
    final gradient = _gradients[hash % _gradients.length];

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl!,
          height: height,
          width: width,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            if (frame == null) return _fallback(theme, gradient);
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return _fallback(theme, gradient);
          },
        ),
      );
    }

    return _fallback(theme, gradient);
  }

  Widget _fallback(ThemeData theme, List<Color> gradient) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(Icons.circle_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.25)),
          ),
          Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 36,
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
