import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'task_column.dart';

/// 用户活动分组（用户活动 → 用户任务 → 用户故事 的第一层）
///
/// 取消"泳道"概念：用户活动是包含用户任务的上级分组，
/// 组内以"用户任务"为最小列横向排列；分组自上而下排列。
class ActivitySection extends StatelessWidget {
  final UserActivity activity;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const ActivitySection({
    super.key,
    required this.activity,
    this.onStoryMove,
    this.onStoryTap,
  });

  static Color _getAccentColor(int order) {
    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
    ];
    return colors[order % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(activity.order);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 活动头：小色标 + 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 4.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 任务列：组内最小列，横向排列（可横向滚动）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...activity.tasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: TaskColumn(
                      task: task,
                      onStoryMove: onStoryMove,
                      onStoryTap: onStoryTap,
                    ),
                  );
                }).toList(),
                if (activity.tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '(no tasks)',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
