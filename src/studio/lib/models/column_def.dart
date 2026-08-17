import 'story_map_models.dart';

/// 列定义（页面层视图模型）
///
/// 二维矩阵的列驱动结构：整张地图固定为若干列（ColumnDef），
/// 每一列包含活动标题（跨列合并）、任务标题以及按 Release 分组的故事列表。
/// 渲染时自上而下输出行（活动层 → 任务层 → Release 行 × N），
/// 同一列在每行中的宽度一致，天然对齐。
class ColumnDef {
  /// 跨列系数：该列所属活动连续覆盖的列数（活动层据此跨列合并）
  final int flex;

  /// 活动标题（橙色层）
  final String activityTitle;

  /// 任务标题（紫色层）
  final String taskTitle;

  /// 任务 id（拖放目标与回调使用）
  final String taskId;

  /// 故事列表，Key 为 Release 行（如 'MVP 版本' / '未来迭代'）
  final Map<String, List<Story>> stories;

  const ColumnDef({
    this.flex = 1,
    required this.activityTitle,
    required this.taskTitle,
    required this.taskId,
    this.stories = const {},
  });
}

/// 将领域模型（Story列表）投影为列驱动视图模型。
/// 领域模型仍是唯一事实源，页面渲染前投影，不做任何数据变更。
List<ColumnDef> projectToColumns(List<Story> stories) {
  final repo = StoryRepository(stories);
  final activities = repo.activities;
  
  // 收集所有任务，并关联其所属活动
  final tasks = <({String activity, Story task})>[];
  for (final activity in activities) {
    final activityTasks = repo.getTasksForActivity(activity.id);
    for (final task in activityTasks) {
      tasks.add((activity: activity.title, task: task));
    }
  }

  final columns = <ColumnDef>[];
  for (var i = 0; i < tasks.length; i++) {
    // 计算连续同活动列数（活动层跨列合并）
    var span = 1;
    while (i + span < tasks.length &&
        tasks[i + span].activity == tasks[i].activity) {
      span++;
    }
    
    // 获取该任务下的所有故事
    final taskStories = repo.getStoriesForTask(tasks[i].task.id);
    
    columns.add(
      ColumnDef(
        flex: span,
        activityTitle: tasks[i].activity,
        taskTitle: tasks[i].task.title,
        taskId: tasks[i].task.id,
        stories: _groupStoriesByPhase(taskStories),
      ),
    );
  }
  return columns;
}

/// 收集所有 Release 行（按阶段枚举顺序，仅含实际有故事的版本）
List<String> collectReleases(List<ColumnDef> columns) {
  final releases = <String>[];
  for (final phase in ReleasePhase.values) {
    if (columns.any((column) => column.stories.containsKey(phase.label))) {
      releases.add(phase.label);
    }
  }
  return releases;
}

/// 按发布阶段（Release 行）分组故事
Map<String, List<Story>> _groupStoriesByPhase(List<Story> stories) {
  final grouped = <String, List<Story>>{};
  for (final story in stories) {
    grouped.putIfAbsent(story.phase.label, () => []).add(story);
  }
  return grouped;
}