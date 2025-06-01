import 'package:flutter/material.dart';

class CustomNavIcon extends StatelessWidget {
  final String iconPath;
  final String selectedIconPath;
  final bool isSelected;
  final double size;

  const CustomNavIcon({
    Key? key,
    required this.iconPath,
    required this.selectedIconPath,
    required this.isSelected,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isSelected ? selectedIconPath : iconPath,
      width: size,
      height: size,
    );
  }
}
