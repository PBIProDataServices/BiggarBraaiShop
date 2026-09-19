import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  const TextWidget({
    Key? key,
    required this.text,
    this.color = Colors.white,
    this.textSize = 18,
    this.isTitle = false,
    this.maxLines = 10,
    this.fontWeight = FontWeight.normal,
  }) : super(key: key);

  final String text;
  final Color color;
  final double textSize;
  final bool isTitle;
  final int maxLines;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: textSize,
        fontWeight: isTitle ? FontWeight.bold : fontWeight,
        letterSpacing: isTitle ? -0.5 : 0,
        height: 1.2,
      ),
    );
  }
}
