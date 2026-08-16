import 'package:flutter/material.dart';
import '../models/story_map_models.dart';

/// 故事明细卡
/// 代表一个 UserStory 的最小视觉单元
///
/// 视觉减负约定：
/// - 白色卡片 + 细浅边框，不按阶段着色
/// - 标题为动词开头的用户语言；具体命令放入 description 副文本（第二层）
/// - 状态用右上角圆点：🟢 完成 / 🟡 进行中 / ⚪ 待办
/// - 发布阶段只以极小灰色文字弱化提示
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
    final statusColor = _getStatusColor(story.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => onLongPress?.call(story),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: [
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
                // 第一层：标题 + 状态圆点
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(width: 6.0),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: _StatusDot(color: statusColor),
                    ),
                  ],
                ),
                // 第二层：描述（具体命令 / 技术细节，弱化显示）
                if (story.description != null && story.description!.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    story.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.0,
                      height: 1.3,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                // 第三层：发布阶段（极小文字弱化）
                const SizedBox(height: 5.0),
                Text(
                  story.phase.label,
                  style: TextStyle(
                    fontSize: 9.0,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取状态颜色（圆点）
  Color _getStatusColor(StoryStatus status) {
    switch (status) {
      case StoryStatus.todo:
        return const Color(0xFFB0BEC5); // 浅灰
      case StoryStatus.inProgress:
        return const Color(0xFFF39C12); // 琥珀
      case StoryStatus.done:
        return const Color(0xFF27AE60); // 绿
    }
  }
}

/// 状态圆点：右上角的小圆点，替代大号状态标签
class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
