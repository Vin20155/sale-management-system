import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/services/mart_service.dart';

class ProductImage extends StatelessWidget {
  final int? productId;
  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  const ProductImage({
    super.key,
    this.productId,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.placeholderIcon = Icons.fastfood_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MartService().resolveProductImageUrl(
      imageUrl,
      productId: productId,
    );
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: AppColors.primary, size: 28),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: resolvedUrl == null
          ? placeholder
          : Image.network(
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
