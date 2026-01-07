import 'package:flutter/material.dart';
import 'models/story_map_models.dart';
import 'widgets/story_map_canvas.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QtCloud Studio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static StoryMap _createSampleData() {
    // 第一个活动：对话（Dialogue）
    final dialogueActivity = UserActivity(
      id: 'activity-1',
      title: '对话 (Dialogue)',
      order: 0,
      tasks: [
        UserTask(
          id: 'task-1',
          title: '开始对话',
          activityId: 'activity-1',
          order: 0,
          stories: [
            UserStory(
              id: 'story-1',
              title: '输入消息到聊天框',
              taskId: 'task-1',
              phase: ReleasePhase.mvp,
              status: StoryStatus.done,
            ),
            UserStory(
              id: 'story-2',
              title: '查看 AI 回复',
              taskId: 'task-1',
              phase: ReleasePhase.mvp,
              status: StoryStatus.done,
            ),
          ],
        ),
        UserTask(
          id: 'task-2',
          title: '采纳便签',
          activityId: 'activity-1',
          order: 1,
          stories: [
            UserStory(
              id: 'story-3',
              title: '查看便签建议卡片',
              taskId: 'task-2',
              phase: ReleasePhase.mvp,
              status: StoryStatus.inProgress,
            ),
            UserStory(
              id: 'story-4',
              title: '点击采纳',
              taskId: 'task-2',
              phase: ReleasePhase.mvp,
              status: StoryStatus.inProgress,
            ),
          ],
        ),
      ],
    );

    // 第二个活动：白板（Whiteboard）
    final whiteboardActivity = UserActivity(
      id: 'activity-2',
      title: '白板 (Whiteboard)',
      order: 1,
      tasks: [
        UserTask(
          id: 'task-3',
          title: '挑选便签',
          activityId: 'activity-2',
          order: 0,
          stories: [
            UserStory(
              id: 'story-5',
              title: '浏览便签列表',
              taskId: 'task-3',
              phase: ReleasePhase.mvp,
              status: StoryStatus.done,
            ),
            UserStory(
              id: 'story-6',
              title: '勾选需要的便签',
              taskId: 'task-3',
              phase: ReleasePhase.mvp,
              status: StoryStatus.inProgress,
            ),
          ],
        ),
        UserTask(
          id: 'task-4',
          title: '生成备忘',
          activityId: 'activity-2',
          order: 1,
          stories: [
            UserStory(
              id: 'story-7',
              title: '点击"生成备忘录"按钮',
              taskId: 'task-4',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
            UserStory(
              id: 'story-8',
              title: '自动跳转至画布',
              taskId: 'task-4',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
          ],
        ),
      ],
    );

    // 第三个活动：笔记（Notebook）
    final notebookActivity = UserActivity(
      id: 'activity-3',
      title: '笔记 (Notebook)',
      order: 2,
      tasks: [
        UserTask(
          id: 'task-5',
          title: '编辑备忆',
          activityId: 'activity-3',
          order: 0,
          stories: [
            UserStory(
              id: 'story-9',
              title: '查看自动生成草稿',
              taskId: 'task-5',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
            UserStory(
              id: 'story-10',
              title: '选择收件人',
              taskId: 'task-5',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
            UserStory(
              id: 'story-11',
              title: '选择目的',
              taskId: 'task-5',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
          ],
        ),
        UserTask(
          id: 'task-6',
          title: '发送结果',
          activityId: 'activity-3',
          order: 1,
          stories: [
            UserStory(
              id: 'story-12',
              title: '点击"发送"按钮',
              taskId: 'task-6',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
            UserStory(
              id: 'story-13',
              title: '显示成功提示 (Toast)',
              taskId: 'task-6',
              phase: ReleasePhase.future,
              status: StoryStatus.todo,
            ),
          ],
        ),
      ],
    );

    return StoryMap(
      id: 'map-1',
      name: 'AI 协作平台用户故事地图',
      activities: [
        dialogueActivity,
        whiteboardActivity,
        notebookActivity,
      ],
      mvpLinePosition: 0.45,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sampleData = _createSampleData();

    return StoryMapCanvasPage(
      mapData: sampleData,
      onStoryMove: (story, newTaskId) {
        debugPrint('故事移动: ${story.title} -> 任务 $newTaskId');
      },
      onStoryTap: (story) {
        debugPrint('点击故事: ${story.title}');
      },
      onMVPLineMove: (position) {
        debugPrint('Release Line 移动到: ${(position * 100).toStringAsFixed(1)}%');
      },
    );
  }
}
