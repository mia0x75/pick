import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/focusable_card.dart';

class FavoriteCard extends StatelessWidget {
  final String name;
  final String? posterUrl;
  final IconData? icon;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;

  const FavoriteCard({
    super.key,
    required this.name,
    this.posterUrl,
    this.icon,
    this.onSelect,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableCard(
      onSelect: onSelect,
      onMenu: onMenu,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: posterUrl != null && posterUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
                    errorWidget: (_, __, ___) => _buildIcon(),
                  )
                : _buildIcon(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Icon(
          icon ?? Icons.folder,
          color: const Color(0xFFFF6B35),
          size: 48.sp,
        ),
      ),
    );
  }
}
