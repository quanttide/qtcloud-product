import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'task_card.dart';

/// 泳道容器
/// 代表一个 UserActivity 的横向容器
/// 职责：横向布局、背景色区分、标题展示
class ActivityLane extends StatelessWidget {
  final UserActivity activity;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const ActivityLane({
    required this.activity,
    this.onStoryMove,
    this.onStoryTap,
  });

  static Color _getActivityColor(int order) {
    final colors = [
      const Color(0xFFF0F7FF),
      const Color(0xFFF0FFF4),
      const Color(0xFFFFFBEA),
      const Color(0xFFFFEAE5),
      const Color(0xFFFAF0FF),
      const Color(0xFFF0F8F8),
    ];
    return colors[order % colors.length];
  }

  static Color _getTitleBarColor(int order) {
    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
      const Color(0xFFE74C3C),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[order % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getActivityColor(activity.order);
    final titleColor = _getTitleBarColor(activity.order);

    return Container(
      width: 300.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: titleColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              activity.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
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
