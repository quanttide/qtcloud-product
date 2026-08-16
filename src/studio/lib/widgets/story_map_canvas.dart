import 'package:flutter/material.dart';
import '../models/column_def.dart';
import '../models/story_map_models.dart';
import 'story_card.dart';

/// 矩阵列宽与列间距（所有行保持一致，保证列对齐）
const double _columnWidth = 220.0;
const double _columnGap = 8.0;

/// 跨列单元格宽度：活动层跨列合并时使用
double _cellWidth(int span) => span * (_columnWidth + _columnGap) - _columnGap;

/// 故事地图画布页（独立页面，含 AppBar）
/// 供独立路由使用；嵌入产品空间时请直接使用 [StoryMapCanvasView]。
class StoryMapCanvasPage extends StatelessWidget {
  final StoryMap mapData;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const StoryMapCanvasPage({
    super.key,
    required this.mapData,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('量潮产品云 · ${mapData.name}'),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: StoryMapCanvasView(
        mapData: mapData,
        onStoryMove: onStoryMove,
        onStoryTap: onStoryTap,
      ),
    );
  }
}

/// 故事地图画布视图（无 Scaffold，可嵌入任意布局）
///
/// 需求屏（用户故事地图看板）：二维矩阵 + 跨列合并。
/// - X 轴（列）：任务列；每列 = 活动层（橙，跨列合并）+ 任务层（紫）+ 故事卡片
/// - Y 轴（行）：Release 版本行（如 'MVP 版本' / '未来迭代'），可折叠
/// - 领域模型经 [projectToColumns] 投影为列驱动结构渲染
class StoryMapCanvasView extends StatefulWidget {
  final StoryMap mapData;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const StoryMapCanvasView({
    super.key,
    required this.mapData,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  State<StoryMapCanvasView> createState() => _StoryMapCanvasViewState();
}

class _StoryMapCanvasViewState extends State<StoryMapCanvasView> {
  /// 已折叠的 Release 行
  final Set<String> _collapsedReleases = {};

  @override
  void didUpdateWidget(StoryMapCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapData.id != oldWidget.mapData.id) {
      _collapsedReleases.clear();
    }
  }

  void _toggleRelease(String release) {
    setState(() {
      if (!_collapsedReleases.add(release)) {
        _collapsedReleases.remove(release);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = projectToColumns(widget.mapData);
    final releases = collectReleases(columns);

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 活动层（橙色，跨列合并）
                _ActivityLayerRow(columns: columns),
                const SizedBox(height: _columnGap),
                // 2. 任务层（紫色）
                _TaskLayerRow(columns: columns),
                const SizedBox(height: 12.0),
                // 3. Release 行 × N（蓝色故事卡片行，可折叠）
                for (final release in releases) ...[
                  _ReleaseRow(
                    release: release,
                    columns: columns,
                    collapsed: _collapsedReleases.contains(release),
                    onToggle: () => _toggleRelease(release),
                    onStoryMove: widget.onStoryMove,
                    onStoryTap: widget.onStoryTap,
                  ),
                  const SizedBox(height: 8.0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ 活动层（橙色，跨列合并） ============

class _ActivityLayerRow extends StatelessWidget {
  final List<ColumnDef> columns;

  const _ActivityLayerRow({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns.length; i++)
          // 仅渲染每组连续同活动列的第一列，宽度按跨列系数合并
          if (i == 0 ||
              columns[i].activityTitle != columns[i - 1].activityTitle)
            Container(
              width: _cellWidth(columns[i].flex),
              margin: const EdgeInsets.only(right: _columnGap),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                columns[i].activityTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4E342E),
                ),
              ),
            ),
      ],
    );
  }
}

// ============ 任务层（紫色） ============

class _TaskLayerRow extends StatelessWidget {
  final List<ColumnDef> columns;

  const _TaskLayerRow({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final column in columns)
          Container(
            width: _columnWidth,
            margin: const EdgeInsets.only(right: _columnGap),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFB39DDB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              column.taskTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ============ Release 行（可折叠） ============

class _ReleaseRow extends StatelessWidget {
  final String release;
  final List<ColumnDef> columns;
  final bool collapsed;
  final VoidCallback onToggle;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const _ReleaseRow({
    required this.release,
    required this.columns,
    required this.collapsed,
    required this.onToggle,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Release 标题行：灰分隔线 + 版本号 + 折叠三角
        InkWell(
          key: Key('release-toggle-$release'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 2),
                Icon(Icons.event, size: 13, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  release,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (!collapsed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final column in columns)
                _StoryCell(
                  column: column,
                  release: release,
                  onStoryMove: onStoryMove,
                  onStoryTap: onStoryTap,
                ),
            ],
          ),
      ],
    );
  }
}

// ============ 故事单元格（矩阵列容器，拖放目标） ============

class _StoryCell extends StatelessWidget {
  final ColumnDef column;
  final String release;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;

  const _StoryCell({
    required this.column,
    required this.release,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final stories = column.stories[release] ?? const <UserStory>[];

    return Container(
      width: _columnWidth,
      margin: const EdgeInsets.only(right: _columnGap),
      child: DragTarget<UserStory>(
        onAcceptWithDetails: (DragTargetDetails<UserStory> details) {
          final story = details.data;
          // 如果故事属于不同的任务，触发 onStoryMove
          if (story.taskId != column.taskId) {
            onStoryMove?.call(story, column.taskId);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.green
                    : Colors.grey[200]!,
                width: candidateData.isNotEmpty ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                ...stories.map((story) {
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
                if (stories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '—',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
