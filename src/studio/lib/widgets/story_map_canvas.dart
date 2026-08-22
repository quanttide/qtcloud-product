import 'package:flutter/material.dart';
import '../models/column_def.dart';
import '../models/story_map_models.dart';
import 'story_card.dart';

/// 矩阵列宽与列间距（所有泳道保持一致，保证列对齐）
const double _columnWidth = 220.0;
const double _columnGap = 8.0;

/// 列边界线颜色（泳道式划线：贯穿任务/故事泳道，让列纵向对应可见）
const Color _columnDividerColor = Color(0xFFCFD8DC);

/// 跨列单元格宽度：活动泳道跨列合并时使用
double _cellWidth(int span) => span * (_columnWidth + _columnGap) - _columnGap;

/// 故事地图画布页（独立页面，含 AppBar）
/// 供独立路由使用；嵌入产品空间时请直接使用 [StoryMapCanvasView]。
class StoryMapCanvasPage extends StatelessWidget {
  final List<Story> stories;
  final Function(Story, String)? onStoryMove;
  final Function(Story)? onStoryTap;

  const StoryMapCanvasPage({
    super.key,
    required this.stories,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('量潮产品云 · 用户故事地图'),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: StoryMapCanvasView(
        stories: stories,
        onStoryMove: onStoryMove,
        onStoryTap: onStoryTap,
      ),
    );
  }
}

/// 故事地图画布视图（无 Scaffold，可嵌入任意布局）
///
/// 需求屏（用户故事地图看板）：**泳道式**结构。
/// - 横向泳道：活动泳道（橙卡，跨列合并）→ 任务泳道（紫卡，每列一张）
///   → 故事泳道 × N（白卡，每列一个单元格）
/// - 纵向列：泳道式划线——各泳道列宽一致，且任务/故事泳道每列左侧画
///   列边界竖线，使同一「列」（步骤）的活动归属、任务与卡片纵向对齐一目了然。
/// - 领域模型经 [projectToColumns] 投影为列驱动结构渲染。
class StoryMapCanvasView extends StatefulWidget {
  final List<Story> stories;
  final Function(Story, String)? onStoryMove;
  final Function(Story)? onStoryTap;

  const StoryMapCanvasView({
    super.key,
    required this.stories,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  State<StoryMapCanvasView> createState() => _StoryMapCanvasViewState();
}

class _StoryMapCanvasViewState extends State<StoryMapCanvasView> {
  /// 已折叠的 Release 泳道（跨列全局同步）
  final Set<String> _collapsedReleases = {};

  /// 垂直 / 水平滚动控制器（配合常显滚动条）
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StoryMapCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果故事列表变化，清空折叠状态
    if (widget.stories != oldWidget.stories) {
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
    final columns = projectToColumns(widget.stories);
    final releases = collectReleases(columns);

    return Container(
      color: Colors.grey[50],
      // 双层滚动 + 视口叠加滚动条：
      // 内层 Scrollbar 会跟随垂直内容（藏在底部），改为叠加在视口边缘的
      // 常显滚动条（垂直在右、水平在底），保证两个方向都可见、可拖动。
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 泳道 0：活动泳道（橙卡，跨列合并）
                      _ActivityLane(columns: columns),
                      const SizedBox(height: _columnGap),
                      // 泳道 1：任务泳道（紫卡，每列一张）
                      _TaskLane(columns: columns),
                      const SizedBox(height: 12.0),
                      // 泳道 2+：故事泳道 × N（白卡，可折叠）
                      for (final release in releases) ...[
                        _ReleaseLane(
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
          ),
          // 垂直滚动条（右侧，避开水平滚动条）
          Positioned(
            top: 4,
            right: 4,
            bottom: 14,
            width: 10,
            child: _OverlayScrollbar(
              key: const Key('scrollbar-vertical'),
              controller: _verticalController,
              axis: Axis.vertical,
            ),
          ),
          // 水平滚动条（底部，避开垂直滚动条）
          Positioned(
            left: 4,
            right: 14,
            bottom: 4,
            height: 10,
            child: _OverlayScrollbar(
              key: const Key('scrollbar-horizontal'),
              controller: _horizontalController,
              axis: Axis.horizontal,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 泳道 0：活动泳道（橙卡，跨列合并） ============

class _ActivityLane extends StatelessWidget {
  final List<ColumnDef> columns;

  const _ActivityLane({required this.columns});

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
                color: const Color(0xFFFFF3E0),
                border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open, size: 13, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      columns[i].activityTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// ============ 泳道 1：任务泳道（紫卡，每列一张 + 列边界竖线） ============

class _TaskLane extends StatelessWidget {
  final List<ColumnDef> columns;

  const _TaskLane({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final column in columns)
          _LaneCell(
            width: _columnWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                border: Border.all(color: const Color(0xFFB39DDB), width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, size: 13, color: Color(0xFF5E35B1)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      column.taskTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5E35B1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============ 泳道 2+：故事泳道（白卡，每列一个单元格，可折叠） ============

class _ReleaseLane extends StatelessWidget {
  final String release;
  final List<ColumnDef> columns;
  final bool collapsed;
  final VoidCallback onToggle;
  final Function(Story, String)? onStoryMove;
  final Function(Story)? onStoryTap;

  const _ReleaseLane({
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
        // Release 标题行：版本号 + 折叠三角
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

// ============ 泳道单元格：左侧列边界竖线（泳道式划线） ============

class _LaneCell extends StatelessWidget {
  final double width;
  final Widget child;

  const _LaneCell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: _columnGap),
      // 列边界竖线：每列左侧画一条，贯穿同一泳道并纵向对齐
      padding: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: _columnDividerColor, width: 1)),
      ),
      child: child,
    );
  }
}

// ============ 故事单元格（泳道内每列，拖放目标 + 列边界竖线） ============

class _StoryCell extends StatelessWidget {
  final ColumnDef column;
  final String release;
  final Function(Story, String)? onStoryMove;
  final Function(Story)? onStoryTap;

  const _StoryCell({
    required this.column,
    required this.release,
    this.onStoryMove,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final stories = column.stories[release] ?? const <Story>[];

    return Container(
      width: _columnWidth,
      margin: const EdgeInsets.only(right: _columnGap),
      child: DragTarget<Story>(
        onAcceptWithDetails: (DragTargetDetails<Story> details) {
          final story = details.data;
          // 如果故事属于不同的任务，触发 onStoryMove
          // Story 模型无 taskId 字段，通过 parentId 判断（简化）
          if (story.parentId != column.taskId) {
            onStoryMove?.call(story, column.taskId);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            // 列边界竖线在故事泳道纵向对齐（与任务泳道一致）
            padding: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: _columnDividerColor, width: 1),
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? const Color(0xFFE8F5E9)
                    : Colors.white,
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
                    return LongPressDraggable<Story>(
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
            ),
          );
        },
      ),
    );
  }
}

// ============ 叠加式滚动条：常显、可拖动，用于双层滚动矩阵的视口边缘 ============

class _OverlayScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Axis axis;

  const _OverlayScrollbar({
    super.key,
    required this.controller,
    required this.axis,
  });

  @override
  State<_OverlayScrollbar> createState() => _OverlayScrollbarState();
}

class _OverlayScrollbarState extends State<_OverlayScrollbar> {
  double? _dragStartLocal;
  double? _dragStartOffset;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onScrollChanged() {
    if (mounted) setState(() {});
  }

  double _localOf(Offset local) =>
      widget.axis == Axis.vertical ? local.dy : local.dx;

  void _startDrag(DragStartDetails details) {
    _dragStartLocal = _localOf(details.localPosition);
    _dragStartOffset = widget.controller.offset;
  }

  void _updateDrag(DragUpdateDetails details, double track, double thumb) {
    final startLocal = _dragStartLocal;
    final startOffset = _dragStartOffset;
    if (startLocal == null || startOffset == null) return;
    final position = widget.controller.position;
    final delta = _localOf(details.localPosition) - startLocal;
    final newOffset = startOffset +
        delta / (track - thumb) * position.maxScrollExtent;
    widget.controller.jumpTo(
      newOffset.clamp(0.0, position.maxScrollExtent),
    );
  }

  void _endDrag(DragEndDetails details) {
    _dragStartLocal = null;
    _dragStartOffset = null;
  }

  @override
  Widget build(BuildContext context) {
    const thumbMinSize = 24.0;
    final controller = widget.controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 在布局阶段读取滚动位置：此时 content dimensions 已就绪
        // （build 阶段读取会早于布局，导致永远隐藏且无重建通知）
        if (!controller.hasClients) return const SizedBox.shrink();
        final position = controller.position;
        if (!position.hasContentDimensions) return const SizedBox.shrink();
        final maxExtent = position.maxScrollExtent;
        if (maxExtent <= 0) return const SizedBox.shrink();

        final viewport = position.viewportDimension;
        final ratio = viewport / (viewport + maxExtent); // 拇指长度比例
        final fraction = position.pixels / maxExtent; // 拇指位置比例
        final track = widget.axis == Axis.vertical
            ? constraints.maxHeight
            : constraints.maxWidth;
        final thumb = (track * ratio).clamp(thumbMinSize, track);
        final thumbOffset = fraction * (track - thumb);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: widget.axis == Axis.vertical ? _startDrag : null,
          onVerticalDragUpdate: widget.axis == Axis.vertical
              ? (details) => _updateDrag(details, track, thumb)
              : null,
          onVerticalDragEnd: widget.axis == Axis.vertical ? _endDrag : null,
          onHorizontalDragStart: widget.axis == Axis.horizontal ? _startDrag : null,
          onHorizontalDragUpdate: widget.axis == Axis.horizontal
              ? (details) => _updateDrag(details, track, thumb)
              : null,
          onHorizontalDragEnd: widget.axis == Axis.horizontal ? _endDrag : null,
          child: Stack(
            children: [
              // 轨道（半透明，仅在可滚动时显示）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // 拇指（带 Key，供测试断言真实渲染）
              if (widget.axis == Axis.vertical)
                Positioned(
                  key: Key('scrollbar-thumb-${widget.axis.name}'),
                  top: thumbOffset,
                  left: 0,
                  right: 0,
                  height: thumb,
                  child: _Thumb(),
                )
              else
                Positioned(
                  key: Key('scrollbar-thumb-${widget.axis.name}'),
                  left: thumbOffset,
                  top: 0,
                  bottom: 0,
                  width: thumb,
                  child: _Thumb(),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 滚动条拇指
class _Thumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
