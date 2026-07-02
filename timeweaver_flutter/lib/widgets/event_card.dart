import 'package:flutter/material.dart';

import '../app.dart';
import '../models/event_item.dart';
import '../utils/date_utils.dart';
import 'weaving_widgets.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onNavigate,
    this.onShare,
    this.onCopy,
  });

  final EventItem event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onNavigate;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '更多',
                onSelected: (value) {
                  if (value == 'navigate') onNavigate?.call();
                  if (value == 'share') onShare?.call();
                  if (value == 'copy') onCopy?.call();
                  if (value == 'edit') onEdit?.call();
                  if (value == 'duplicate') onDuplicate?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'navigate', child: Text('地图')),
                  PopupMenuItem(value: 'share', child: Text('分享')),
                  PopupMenuItem(value: 'copy', child: Text('复制')),
                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(value: 'duplicate', child: Text('复制')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                icon: Icons.event_available_rounded,
                label: event.eventType,
              ),
              InfoChip(
                icon: Icons.schedule_rounded,
                label: ZhishiDateUtils.formatDateTime(event.startTimeIso),
              ),
              if (event.location != null && event.location!.trim().isNotEmpty)
                InfoChip(icon: Icons.place_outlined, label: event.location!),
            ],
          ),
          if (event.description != null &&
              event.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              event.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
