import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'story_card.dart';

/// 用户任务列（用户活动 → 用户任务 → 用户故事 的第二层）
///
/// 以用户任务为最小列：列头为任务标题，列内纵向堆叠用户故事卡片；
/// 整列是故事卡片的拖放目标（跨任务移动）。
class TaskColumn extends StatelessWidget {
  final UserTask task;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const TaskColumn({
    super.key,
    required this.task,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.0,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列头：任务标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5.0),
              ),
            ),
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF37474F),
              ),
            ),
          ),
          // 故事卡片区（拖放目标）
          DragTarget<UserStory>(
            onAcceptWithDetails: (DragTargetDetails<UserStory> details) {
              final story = details.data;
              // 如果故事属于不同的任务，触发 onStoryMove
              if (story.taskId != task.id) {
                onStoryMove?.call(story, task.id);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? Colors.green
                        : Colors.transparent,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: [
                    ...task.stories.map((story) {
                      return LongPressDraggable<UserStory>(
                        data: story,
                        feedback: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(6.0),
                          child: StoryCard(story: story),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: StoryCard(story: story),
                        ),
                        child: StoryCard(
                          story: story,
                          onTap: () => onStoryTap?.call(story),
                        ),
                      );
                    }),
                    if (task.stories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '(no stories)',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
