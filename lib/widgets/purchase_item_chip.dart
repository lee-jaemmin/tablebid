import 'package:flutter/material.dart';

class PurchaseItemChip extends StatelessWidget {
  final String itemName;
  final VoidCallback onTap;
  final bool isSelected;
  final int quantity;

  const PurchaseItemChip({
    super.key,
    required this.itemName,
    required this.onTap,
    required this.isSelected,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        border: !isSelected
            ? Border.all(color: Colors.grey.shade400)
            : Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                itemName,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              SizedBox(width: 4),
              quantity == 0
                  ? Text("")
                  : Text(
                      '$quantity',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
