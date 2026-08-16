import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'task_card.dart';

/// 泳道容器
/// 代表一个 UserActivity 的横向容器
///
/// 视觉减负约定：
/// - 所有泳道统一浅灰底 + 细边框，不用整列大色块
/// - 列头为白底 + 小色标（4px 竖条）+ 彩色文字，仅作轻度区隔
class ActivityLane extends StatelessWidget {
  final UserActivity activity;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const ActivityLane({
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
      width: 300.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列头：白底 + 小色标 + 彩色文字（非整列色块）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.0),
            ),
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
                const SizedBox(width: 6.0),
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
          const SizedBox(height: 12.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...activity.tasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TaskCard(
                        task: task,
                        onStoryMove: onStoryMove,
                        onStoryTap: onStoryTap,
                      ),
                    );
                  }).toList(),
                  if (activity.tasks.isEmpty)
                    Center(
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
          ),
        ],
      ),
    );
  }
}
