import 'acceptance_models.dart';
import 'dev_task_models.dart';
import 'event_storm_models.dart';
import 'operations_models.dart';
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

  /// 开发任务（用户故事再分析拆解，进入开发看板流转）
  final List<DevTask> devTasks;

  /// 验收项（开发完成后的交付门禁：逐项验证是否符合需求与规格）
  final List<AcceptanceItem> acceptances;

  /// 维护者们的反思（运营观测：维护者对产品运行状态的观察与决策）
  final List<MaintainerThought> maintainerThoughts;

  /// 用户的反馈（真实用户反馈，按类型与处理状态管理）
  final List<UserFeedback> userFeedback;

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
    this.devTasks = const [],
    this.acceptances = const [],
    this.maintainerThoughts = const [],
    this.userFeedback = const [],
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
        if (devTasks.isNotEmpty)
          'devTasks': [for (final t in devTasks) t.toJson()],
        if (acceptances.isNotEmpty)
          'acceptances': [for (final a in acceptances) a.toJson()],
        if (maintainerThoughts.isNotEmpty)
          'maintainerThoughts': [
            for (final t in maintainerThoughts) t.toJson()
          ],
        if (userFeedback.isNotEmpty)
          'userFeedback': [for (final f in userFeedback) f.toJson()],
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
      devTasks: (json['devTasks'] as List<dynamic>? ?? const [])
          .map((e) => DevTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptances: (json['acceptances'] as List<dynamic>? ?? const [])
          .map((e) => AcceptanceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      maintainerThoughts:
          (json['maintainerThoughts'] as List<dynamic>? ?? const [])
              .map((e) => MaintainerThought.fromJson(e as Map<String, dynamic>))
              .toList(),
      userFeedback: (json['userFeedback'] as List<dynamic>? ?? const [])
          .map((e) => UserFeedback.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
