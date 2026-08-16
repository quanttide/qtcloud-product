import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'activity_lane.dart';

/// 故事地图画布页（独立页面，含 AppBar）
/// 供独立路由使用；嵌入侧边导航时请直接使用 [StoryMapCanvasView]。
class StoryMapCanvasPage extends StatelessWidget {
  final StoryMap mapData;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;
  final Function(double)? onMVPLineMove;

  const StoryMapCanvasPage({
    super.key,
    required this.mapData,
    this.onStoryMove,
    this.onStoryTap,
    this.onMVPLineMove,
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
        onMVPLineMove: onMVPLineMove,
      ),
    );
  }
}

/// 故事地图画布视图（无 Scaffold，可嵌入任意布局）
class StoryMapCanvasView extends StatefulWidget {
  final StoryMap mapData;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;
  final Function(double)? onMVPLineMove;

  const StoryMapCanvasView({
    super.key,
    required this.mapData,
    this.onStoryMove,
    this.onStoryTap,
    this.onMVPLineMove,
  });

  @override
  State<StoryMapCanvasView> createState() => _StoryMapCanvasViewState();
}

class _StoryMapCanvasViewState extends State<StoryMapCanvasView> {
  late double mvpLinePosition;

  @override
  void initState() {
    super.initState();
    mvpLinePosition = widget.mapData.mvpLinePosition;
  }

  @override
  void didUpdateWidget(StoryMapCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapData.mvpLinePosition != oldWidget.mapData.mvpLinePosition) {
      mvpLinePosition = widget.mapData.mvpLinePosition;
    }
  }

  void _handleMVPLineDrag(double dy, double maxHeight) {
    setState(() {
      mvpLinePosition = (dy / maxHeight).clamp(0.0, 1.0);
      widget.onMVPLineMove?.call(mvpLinePosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要内容：横向滚动的活动泳道
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            color: Colors.grey[50],
            child: Row(
              children: widget.mapData.activities.map((activity) {
                return ActivityLane(
                  activity: activity,
                  onStoryMove: widget.onStoryMove,
                  onStoryTap: widget.onStoryTap,
                );
              }).toList(),
            ),
          ),
        ),
        // Release Line - 可拖动的分界线
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mvpTop = constraints.maxHeight * mvpLinePosition;
              return MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: Stack(
                  children: [
                    // MVP 标签（弱化）
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'MVP',
                          style: TextStyle(
                            color: Color(0xFFC62828),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    // Release Line（发布线）：细浅色虚线
                    Positioned(
                      top: mvpTop,
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(double.infinity, 1.5),
                        painter: const _DashedLinePainter(Color(0xFF90A4AE)),
                      ),
                    ),
                    // 拖动交互区域
                    Positioned(
                      top: mvpTop - 10,
                      left: 0,
                      right: 0,
                      height: 20.0,
                      child: GestureDetector(
                        onVerticalDragUpdate: (DragUpdateDetails details) {
                          _handleMVPLineDrag(
                            mvpTop + details.delta.dy,
                            constraints.maxHeight,
                          );
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeRow,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // Future 标签（弱化）
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Future',
                          style: TextStyle(
                            color: Color(0xFF607D8B),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 细浅色虚线画笔：用于 Release Line（发布线）
class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
