import 'package:flutter/material.dart';
import 'package:biggar_braai_shop/widgets/text_widget.dart';

import '../services/utils.dart';

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
  }) : super(key: key);

  final String imagePath, title, subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: double.infinity,
              height: size.height * 0.28,
            ),
            const SizedBox(height: 16),
            TextWidget(text: title, color: color, textSize: 22, isTitle: true),
            const SizedBox(height: 8),
            TextWidget(text: subtitle, color: Utils(context).secondaryColor, textSize: 16),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
