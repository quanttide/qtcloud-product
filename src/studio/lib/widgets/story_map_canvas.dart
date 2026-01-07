import 'package:flutter/material.dart';
import '../models/story_map_models.dart';
import 'activity_lane.dart';

class StoryMapCanvasPage extends StatefulWidget {
  final StoryMap mapData;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;
  final Function(double)? onMVPLineMove;

  const StoryMapCanvasPage({
    required this.mapData,
    this.onStoryMove,
    this.onStoryTap,
    this.onMVPLineMove,
  });

  @override
  State<StoryMapCanvasPage> createState() => _StoryMapCanvasPageState();
}

class _StoryMapCanvasPageState extends State<StoryMapCanvasPage> {
  late double mvpLinePosition;

  @override
  void initState() {
    super.initState();
    mvpLinePosition = widget.mapData.mvpLinePosition;
  }

  @override
  void didUpdateWidget(StoryMapCanvasPage oldWidget) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mapData.name),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: Stack(
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
                      // MVP 标签
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MVP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Release Line（发布线）
                      Positioned(
                        top: mvpTop,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFE74C3C),
                                blurRadius: 6.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
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
                      // Future 标签
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF95A5A6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Future',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
      ),
    );
  }
}
