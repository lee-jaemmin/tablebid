import 'package:flutter/material.dart';

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color.fromARGB(255, 112, 10, 10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        border: !isSelected
            ? Border.all(color: Colors.grey.shade300)
            : Border.all(color: Color.fromARGB(255, 112, 10, 10)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: Text(
              region,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1),
            ),
          ),
        ),
      ),
    );
  }
}
