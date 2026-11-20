import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_url.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.placeholderIcon = Icons.fastfood_outlined,
  });

  String _resolveImageUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return '${AppUrl.imageUrl}products/default.jpg';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final cleanPath = value
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp(r'^storage/+'), '');
    return '${AppUrl.imageUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(imageUrl);
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: AppColors.primary, size: 28),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
