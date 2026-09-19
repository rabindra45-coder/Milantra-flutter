import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants.dart';

class AvatarWidget extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;

  const AvatarWidget({super.key, this.url, this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        imageBuilder: (ctx, img) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: img, fit: BoxFit.cover),
          ),
        ),
        placeholder: (ctx, _) => _fallback(),
        errorWidget: (ctx, _, __) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final initial = (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
      ),
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4),
      ),
    );
  }
}
