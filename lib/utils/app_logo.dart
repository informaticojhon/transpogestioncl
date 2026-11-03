import 'package:flutter/material.dart';

/// Logo de TranspoGestión CL (pin con ruta sobre olas).
/// Fuente vectorial en assets/app_icon.svg.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'TranspoGestión CL',
    );
  }
}
