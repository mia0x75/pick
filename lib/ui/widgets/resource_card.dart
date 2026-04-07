import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/models/storage_node.dart';
import '../widgets/focusable_card.dart';

class ResourceCard extends StatelessWidget {
  final StorageNode node;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;

  const ResourceCard({
    super.key,
    required this.node,
    this.onSelect,
    this.onMenu,
  });

  IconData _getIcon() {
    switch (node.type) {
      case StorageType.webdav:
        return Icons.cloud;
      case StorageType.smb:
        return Icons.computer;
      case StorageType.ftp:
        return Icons.folder_open;
      case StorageType.nfs:
        return Icons.storage;
      case StorageType.usb:
        return Icons.usb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableCard(
      onSelect: onSelect,
      onMenu: onMenu,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              color: const Color(0xFFFF6B35),
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              node.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Text(
              node.type.name.toUpperCase(),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
