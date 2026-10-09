import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';

class AxiosLogo extends StatelessWidget {
  const AxiosLogo({super.key, this.size = 92, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      'assets/images/axios_logo.svg',
      width: size,
      height: size,
      semanticsLabel: 'Logo Axios',
    );
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 14),
        Text(
          'Axios',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: size * 0.36,
            letterSpacing: -0.8,
            color: AppColors.graphite,
          ),
        ),
      ],
    );
  }
}
