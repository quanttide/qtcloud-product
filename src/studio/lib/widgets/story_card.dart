import 'package:flutter/material.dart';
import '../models/story_map_models.dart';

/// 故事明细卡
/// 代表一个 Story 的最小视觉单元 / 操作单元
///
/// 信息约定：卡片只展示标题 + 状态色点（待办/进行中/评审中/已完成），
/// 不做详情展示；提供可交互的视觉暗示（hover 高亮 + 操作图标 + 点击/长按拖拽）。
class StoryCard extends StatefulWidget {
  final Story story;
  final VoidCallback? onTap;
  final Function(Story)? onLongPress;

  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  bool _hovered = false;

  /// 状态色点颜色（与开发看板列色一致）
  Color _statusColor(StoryStatus status) => switch (status) {
        StoryStatus.todo => const Color(0xFF9E9E9E),
        StoryStatus.inProgress => const Color(0xFF1976D2),
        StoryStatus.review => const Color(0xFF7B1FA2),
        StoryStatus.done => const Color(0xFF388E3C),
      };

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: () => widget.onLongPress?.call(story),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFE3F2FD) : Colors.white,
              border: Border.all(
                color: _hovered ? const Color(0xFF1976D2) : Colors.grey[300]!,
                width: _hovered ? 1.4 : 1.0,
              ),
              borderRadius: BorderRadius.circular(6.0),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 状态色点：待办灰 / 进行中蓝 / 评审中紫 / 已完成绿
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(story.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // 交互暗示：hover 时出现操作图标
                      if (_hovered)
                        const Icon(
                          Icons.open_in_full,
                          size: 12,
                          color: Color(0xFF1976D2),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
