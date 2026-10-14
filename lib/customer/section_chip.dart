import 'package:flutter/material.dart';

class SectionChip extends StatelessWidget {
  final String region;
  final bool isSelected;
  final VoidCallback onTap;

  const SectionChip({
    super.key,
    required this.region,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
        border: !isSelected
            ? Border.all(color: Colors.grey.shade500)
            : Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Text(
              region,
              textAlign: TextAlign.center,
              style: TextStyle(height: 1, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500),
            ),
          ),
        ),
      ),
    );
  }
}
