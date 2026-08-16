import 'story_map_models.dart';

/// 产品
///
/// 组合层（产品组合 → 产品 → 用户故事地图）的第二层：
/// 一个可独立决策与交付的产品，包含其用户故事地图与设计思路。
class Product {
  final String id;
  final String name;
  final String tagline; // 一句话定位
  final String designIdea; // 设计思路
  final StoryMap storyMap;

  const Product({
    required this.id,
    required this.name,
    required this.tagline,
    required this.designIdea,
    required this.storyMap,
  });

  /// 用户故事总数（跨活动统计）
  int get totalStories => storyMap.activities
      .expand((activity) => activity.tasks)
      .expand((task) => task.stories)
      .length;

  /// MVP 版本的用户故事数
  int get mvpStories => storyMap.activities
      .expand((activity) => activity.tasks)
      .expand((task) => task.stories)
      .where((story) => story.phase == ReleasePhase.mvp)
      .length;

  @override
  String toString() => 'Product(id: $id, name: $name, stories: $totalStories)';
}
