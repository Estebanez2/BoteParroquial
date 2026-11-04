import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = AppSpacing.xxxl});
  static const asset = 'assets/branding/bote_parroquial.png';
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.control,
    child: Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      semanticLabel: 'Logo de BoteParroquial',
    ),
  );
}

/// Decorative, static and independent of authentication or remote data.
class AppLogoBackdrop extends StatelessWidget {
  const AppLogoBackdrop({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Opacity(
        opacity: .12,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const RadialGradient(
            radius: .8,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, .6, 1],
          ).createShader(bounds),
          child: Image.asset(AppLogo.asset, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
