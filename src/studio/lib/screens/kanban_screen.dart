import 'package:flutter/material.dart';

import '../models/dev_task_models.dart';
import '../models/story_map_models.dart';

/// 看板列定义（开发过程状态列）
class _KanbanColumn {
  final StoryStatus status;
  final String title;
  final Color color;

  const _KanbanColumn(this.status, this.title, this.color);
}

const _columns = [
  _KanbanColumn(StoryStatus.todo, '未开始', Color(0xFF9E9E9E)),
  _KanbanColumn(StoryStatus.inProgress, '进行中', Color(0xFF1976D2)),
  _KanbanColumn(StoryStatus.review, '评审中', Color(0xFF7B1FA2)),
  _KanbanColumn(StoryStatus.done, '已完成', Color(0xFF388E3C)),
];

/// 开发看板：以状态列管理开发任务流转
///
/// 数据源为开发任务（用户故事经再分析拆解出的 DevTask），按状态投影到各列；
/// 任务卡片标注来源用户故事（可追溯）；拖拽跨列移动状态（MVP 为内存态）。
class KanbanScreen extends StatefulWidget {
  const KanbanScreen({
    super.key,
    required this.devTasks,
    required this.stories,
  });

  /// 开发任务（看板卡片）
  final List<DevTask> devTasks;

  /// 用户故事（用于解析任务来源故事标题）
  final List<Story> stories;

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  late Map<StoryStatus, List<DevTask>> _columnsByStatus;
  StoryStatus? _hoverStatus;

  @override
  void initState() {
    super.initState();
    _rebuildColumns();
  }

  @override
  void didUpdateWidget(KanbanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devTasks != widget.devTasks) {
      _rebuildColumns();
    }
  }

  void _rebuildColumns() {
    final grouped = <StoryStatus, List<DevTask>>{
      for (final column in _columns) column.status: [],
    };
    for (final task in widget.devTasks) {
      grouped.putIfAbsent(task.status, () => []).add(task);
    }
    _columnsByStatus = grouped;
  }

  /// 来源故事标题（按 storyId 解析，找不到则显示 id）
  String _storyTitleOf(DevTask task) {
    for (final story in widget.stories) {
      if (story.id == task.storyId) return story.title;
    }
    return task.storyId;
  }

  void _moveTask(DevTask task, StoryStatus target) {
    if (task.status == target) return;
    setState(() {
      _columnsByStatus[task.status]?.remove(task);
      _columnsByStatus.putIfAbsent(target, () => []).add(
            task.copyWith(status: target),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final column in _columns) ...[
            Expanded(
              child: _KanbanColumnView(
                column: column,
                tasks: _columnsByStatus[column.status] ?? const [],
                storyTitleOf: _storyTitleOf,
                hovered: _hoverStatus == column.status,
                onHover: (hovered) => setState(() {
                  _hoverStatus = hovered ? column.status : null;
                }),
                onDrop: (task) => _moveTask(task, column.status),
              ),
            ),
            if (column != _columns.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

/// 看板列视图（列头 + 任务卡片列表）
class _KanbanColumnView extends StatelessWidget {
  final _KanbanColumn column;
  final List<DevTask> tasks;
  final String Function(DevTask) storyTitleOf;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final ValueChanged<DevTask> onDrop;

  const _KanbanColumnView({
    required this.column,
    required this.tasks,
    required this.storyTitleOf,
    required this.hovered,
    required this.onHover,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<DevTask>(
      onWillAcceptWithDetails: (details) {
        onHover(true);
        return true;
      },
      onLeave: (_) => onHover(false),
      onAcceptWithDetails: (details) {
        onHover(false);
        onDrop(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: Key('kanban-column-${column.status.name}'),
          decoration: BoxDecoration(
            color: hovered ? const Color(0xFFE3F2FD) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hovered ? const Color(0xFF1976D2) : Colors.grey[300]!,
              width: hovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 列头：标题 + 计数
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: column.color,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      column.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 任务卡片列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Draggable<DevTask>(
                      data: task,
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 220,
                          child: Opacity(
                            opacity: 0.9,
                            child: _TaskCard(
                              task: task,
                              storyTitle: storyTitleOf(task),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _TaskCard(
                          task: task,
                          storyTitle: storyTitleOf(task),
                        ),
                      ),
                      child: _TaskCard(
                        task: task,
                        storyTitle: storyTitleOf(task),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 任务卡片：任务标题 + 来源用户故事
class _TaskCard extends StatelessWidget {
  final DevTask task;
  final String storyTitle;

  const _TaskCard({required this.task, required this.storyTitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF37474F),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '← $storyTitle',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
