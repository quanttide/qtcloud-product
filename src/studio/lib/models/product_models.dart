import 'event_storm_models.dart';
import 'story_map_models.dart';

/// 产品
///
/// 组合层（产品组合 → 产品 → 用户故事地图）的第二层：
/// 一个可独立决策与交付的产品，包含其用户故事地图与设计思路。
class Product {
  final String id;

  /// 唯一命名（URL / 识别场景），如 qtcloud-devops
  final String name;

  /// 前台展示标题，如 量潮DevOps云
  final String title;

  final String tagline; // 一句话定位
  final String designIdea; // 设计思路
  final StoryMap storyMap; // 保留旧格式兼容

  /// 事件风暴规格（可选：种子数据未提供时为 null）
  final EventStorming? eventStorm;
  
  // 缓存转换后的Story列表
  late final List<Story> _stories;
  late final StoryRepository _repository;

  Product({
    required this.id,
    required this.name,
    required this.title,
    required this.tagline,
    required this.designIdea,
    required this.storyMap,
    this.eventStorm,
  }) {
    // 从旧的StoryMap转换为新的Story列表
    _stories = LegacyConverter.fromLegacyStoryMap({
      'storyMap': storyMap.toJson(),
    });
    _repository = StoryRepository(_stories);
  }

  /// 获取Story仓库（新模型）
  StoryRepository get repository => _repository;

  /// 获取所有Story（新模型）
  List<Story> get stories => List.unmodifiable(_stories);

  /// 用户故事总数（跨活动统计）
  int get totalStories => _stories.where((s) => s.isStory).length;

  /// MVP 版本的用户故事数
  int get mvpStories => _stories
      .where((s) => s.isStory && s.phase == ReleasePhase.mvp)
      .length;

  @override
  String toString() => 'Product(id: $id, name: $name, stories: $totalStories)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'tagline': tagline,
        'designIdea': designIdea,
        'storyMap': storyMap.toJson(),
        if (eventStorm != null) 'eventStorm': eventStorm!.toJson(),
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String? ?? (json['name'] as String),
      tagline: json['tagline'] as String? ?? '',
      designIdea: json['designIdea'] as String? ?? '',
      storyMap: StoryMap.fromJson(json['storyMap'] as Map<String, dynamic>),
      eventStorm: json['eventStorm'] != null
          ? EventStorming.fromJson(json['eventStorm'] as Map<String, dynamic>)
          : null,
    );
  }
}
