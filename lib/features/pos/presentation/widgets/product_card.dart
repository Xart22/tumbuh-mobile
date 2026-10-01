import 'package:flutter/material.dart';
import '../../../../data/models/pos_product.dart';
import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class ProductCard extends StatelessWidget {
  final PosProduct product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockQuantity <= 6;

    return Semantics(
      button: true,
      label: '${product.name}, ${CurrencyFormatter.format(product.price)}',
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: LpColors.primaryGreen.withAlpha(50),
        highlightColor: LpColors.surfaceCardHover,
        child: Ink(
          decoration: BoxDecoration(
            color: LpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: product.isBestSeller
                  ? LpColors.primaryGreen.withAlpha(120)
                  : LpColors.borderDark,
              width: product.isBestSeller ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Stock Badge & Best Seller Tag
                Stack(
                  children: [
                    // Product visual placeholder / banner
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: LpColors.surfacePanel,
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            LpColors.surfacePanel,
                            LpColors.surfaceCardHover,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(product.categoryId),
                          size: 38,
                          color: product.isBestSeller
                              ? LpColors.primaryGreen
                              : LpColors.textSecondary,
                        ),
                      ),
                    ),
                    // Top Right Stock Badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? const Color(0xFF451A03).withAlpha(220)
                              : const Color(0xFF064E3B).withAlpha(220),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLowStock
                                ? const Color(0xFFD97706)
                                : LpColors.primaryGreen.withAlpha(150),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? const Color(0xFFF59E0B)
                                    : LpColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLowStock
                                  ? 'Sisa ${product.stockQuantity.toInt()} porsi!'
                                  : 'Stok ${product.stockQuantity.toInt()}',
                              style: LpTypography.labelSm.copyWith(
                                fontSize: 10,
                                color: isLowStock
                                    ? const Color(0xFFFCD34D)
                                    : LpColors.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Best Seller Tag (bottom left)
                    if (product.isBestSeller)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BEST SELLER ⭐',
                            style: LpTypography.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: LpColors.accentAmber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LpTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Description
                if (product.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LpTypography.bodySm.copyWith(
                      color: LpColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                const Divider(color: LpColors.borderDark, height: 12),
                // Bottom Price and + Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga',
                          style: LpTypography.labelSm.copyWith(
                            color: LpColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: LpTypography.dataCurrencySm.copyWith(
                            color: product.isBestSeller
                                ? LpColors.primaryLight
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Touch friendly + action
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: product.isBestSeller
                            ? LpColors.primaryGreen
                            : LpColors.surfacePanel,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: product.isBestSeller
                              ? LpColors.primaryLight.withAlpha(120)
                              : LpColors.borderDark,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: product.isBestSeller
                              ? Colors.white
                              : LpColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  IconData _getCategoryIcon(String catId) {
    switch (catId) {
      case 'cat_espresso':
        return Icons.coffee_rounded;
      case 'cat_noncoffee':
        return Icons.local_drink_rounded;
      case 'cat_food':
        return Icons.dinner_dining_rounded;
      case 'cat_pastry':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}
