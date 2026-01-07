import 'package:flutter/material.dart';
import '../models/story_map_models.dart';

/// 故事明细卡
/// 代表一个 UserStory 的最小视觉单元
/// 职责：显示故事标题、发布阶段、状态标签
class StoryCard extends StatelessWidget {
  final UserStory story;
  final VoidCallback? onTap;
  final Function(UserStory)? onLongPress;

  const StoryCard({
    required this.story,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final phaseColor = _getPhaseColor(story.phase);
    final statusColor = _getStatusColor(story.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => onLongPress?.call(story),
        child: Container(
          decoration: BoxDecoration(
            color: phaseColor['bg'],
            border: Border.all(
              color: phaseColor['border'] ?? Colors.grey,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6.0),
                // 标签行
                Row(
                  children: [
                    // 发布阶段标签
                    _buildTag(
                      story.phase.label,
                      phaseColor['tag'] ?? Colors.grey,
                    ),
                    const SizedBox(width: 4.0),
                    // 状态标签
                    _buildTag(
                      story.status.label,
                      statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标签小部件
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 获取发布阶段相关颜色
  Map<String, Color> _getPhaseColor(ReleasePhase phase) {
    switch (phase) {
      case ReleasePhase.mvp:
        return {
          'bg': const Color(0xFFE8F5E9),
          'border': const Color(0xFF27AE60),
          'tag': const Color(0xFF27AE60),
        };
      case ReleasePhase.future:
        return {
          'bg': const Color(0xFFEBF5FB),
          'border': const Color(0xFF3498DB),
          'tag': const Color(0xFF3498DB),
        };
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(StoryStatus status) {
    switch (status) {
      case StoryStatus.todo:
        return const Color(0xFF95A5A6);
      case StoryStatus.inProgress:
        return const Color(0xFFF39C12);
      case StoryStatus.done:
        return const Color(0xFF27AE60);
    }
  }
}
