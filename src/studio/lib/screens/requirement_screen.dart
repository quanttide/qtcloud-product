import 'package:flutter/material.dart';

import '../models/story_map_models.dart';
import '../widgets/story_map_canvas.dart';

/// 需求屏：用户故事地图看板（二维矩阵）
///
/// 展示一个产品的全部用户故事：活动层（橙，跨列合并）→ 任务层（紫）
/// → Release 行（可折叠）。只负责渲染，不修改数据。
class RequirementScreen extends StatelessWidget {
  final List<Story> stories;

  const RequirementScreen({super.key, required this.stories});

  void _debugStoryMove(Story story, String newTaskId) {
    debugPrint('故事移动: ${story.title} -> 任务 $newTaskId');
  }

  void _debugStoryTap(Story story) {
    debugPrint('点击故事: ${story.title}');
  }

  @override
  Widget build(BuildContext context) {
    return StoryMapCanvasView(
      stories: stories,
      onStoryMove: _debugStoryMove,
      onStoryTap: _debugStoryTap,
    );
  }
}
