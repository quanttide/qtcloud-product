import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'story_card.dart';

/// 任务卡片组
/// 代表一个 UserTask 的视觉卡片
/// 职责：显示任务标题、作为故事卡片的容器、处理拖拽交互
class TaskCard extends StatelessWidget {
  final UserTask task;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const TaskCard({required this.task, this.onStoryMove, this.onStoryTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFF34495E),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        // 故事卡片列表
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
                  }).toList(),
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
    );
  }
}
