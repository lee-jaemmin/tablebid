import 'package:flutter/material.dart';
import 'package:tablebid/widgets/purchase_item_chip.dart';

class RegionChip extends StatelessWidget {
  final String region;
  final bool isSelected;
  final VoidCallback onTap;

  const RegionChip({
    super.key,
    required this.region,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PurchaseItemChip(
      itemName: region,
      onTap: onTap,
      isSelected: isSelected,
      quantity: 0,
    );
  }
}
