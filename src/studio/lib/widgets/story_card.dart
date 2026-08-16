import 'package:flutter/material.dart';
import '../models/story_map_models.dart';

/// 故事明细卡
/// 代表一个 UserStory 的最小视觉单元
///
/// 精简约定：卡片只展示用户故事标题，不做其他信息展示
/// （描述、发布阶段、状态等数据保留在模型中，由 CLI 加工、其他视图使用）。
class StoryCard extends StatelessWidget {
  final UserStory story;
  final VoidCallback? onTap;
  final Function(UserStory)? onLongPress;

  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
        ),
      ),
    );
  }
}
