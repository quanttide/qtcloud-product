/// 用户故事地图的领域模型（扁平化版本）
/// 所有层级（活动、任务、故事）统一为Story模型，通过level和parentId表示层级关系

// ============= 发布阶段枚举 =============
enum ReleasePhase {
  mvp('MVP 版本'),
  future('未来迭代');

  final String label;

  const ReleasePhase(this.label);
}

// ============= 故事状态枚举 =============
enum StoryStatus {
  todo('To Do'),
  inProgress('In Progress'),
  done('Done');

  final String label;

  const StoryStatus(this.label);
}

// ============= 层级枚举 =============
enum StoryLevel {
  activity(0, '活动'),
  task(1, '任务'),
  story(2, '故事');

  final int value;
  final String label;

  const StoryLevel(this.value, this.label);
}

// ============= 统一Story模型 =============
/// 扁平化的故事模型，代表用户故事地图中的所有实体
/// 通过level区分层级，通过parentId建立层级关系
class Story {
  final String id;
  final String title;
  final String? description;
  final ReleasePhase phase;
  final StoryStatus status;
  final StoryLevel level;
  final String? parentId; // 父级ID，活动层级为null
  final int order; // 排序顺序
  final String? color; // 颜色，仅活动层级使用

  const Story({
    required this.id,
    required this.title,
    this.description,
    this.phase = ReleasePhase.mvp,
    this.status = StoryStatus.todo,
    required this.level,
    this.parentId,
    this.order = 0,
    this.color,
  });

  // 是否为活动层级
  bool get isActivity => level == StoryLevel.activity;
  
  // 是否为任务层级
  bool get isTask => level == StoryLevel.task;
  
  // 是否为故事层级
  bool get isStory => level == StoryLevel.story;

  // 用于创建修改后的副本
  Story copyWith({
    String? id,
    String? title,
    String? description,
    ReleasePhase? phase,
    StoryStatus? status,
    StoryLevel? level,
    String? parentId,
    int? order,
    String? color,
  }) {
    return Story(
      id: id ?? this.id,
      title: id ?? this.title,
      description: description ?? this.description,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
      color: color ?? this.color,
    );
  }

  @override
  String toString() =>
      'Story(id: $id, title: $title, level: ${level.label}, phase: ${phase.label})';

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'phase': phase.name,
        'status': status.name,
        'level': level.value,
        if (parentId != null) 'parentId': parentId,
        'order': order,
        if (color != null) 'color': color,
      };

  /// JSON 反序列化
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      phase: ReleasePhase.values.byName(json['phase'] as String),
      status: StoryStatus.values.byName(json['status'] as String),
      level: StoryLevel.values.firstWhere(
        (l) => l.value == json['level'] as int,
        orElse: () => StoryLevel.story,
      ),
      parentId: json['parentId'] as String?,
      order: json['order'] as int? ?? 0,
      color: json['color'] as String?,
    );
  }
}

// ============= 故事仓库（查询辅助） =============
/// 提供层级查询和操作的辅助类
class StoryRepository {
  final List<Story> _stories;

  const StoryRepository(this._stories);

  /// 获取所有故事
  List<Story> get allStories => List.unmodifiable(_stories);

  /// 获取所有活动
  List<Story> get activities => 
      _stories.where((s) => s.isActivity).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// 获取所有任务
  List<Story> get tasks => 
      _stories.where((s) => s.isTask).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// 获取所有故事（最底层）
  List<Story> get stories => 
      _stories.where((s) => s.isStory).toList();

  /// 获取某个活动下的所有任务
  List<Story> getTasksForActivity(String activityId) =>
      _stories.where((s) => s.isTask && s.parentId == activityId).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// 获取某个任务下的所有故事
  List<Story> getStoriesForTask(String taskId) =>
      _stories.where((s) => s.isStory && s.parentId == taskId).toList();

  /// 获取某个活动下的所有故事（递归）
  List<Story> getAllStoriesForActivity(String activityId) {
    final result = <Story>[];
    final tasks = getTasksForActivity(activityId);
    for (final task in tasks) {
      result.addAll(getStoriesForTask(task.id));
    }
    return result;
  }

  /// 获取完整层级树（活动 → 任务列表 → 故事列表）
  Map<Story, Map<Story, List<Story>>> getHierarchy() {
    final hierarchy = <Story, Map<Story, List<Story>>>{};
    
    for (final activity in activities) {
      final taskMap = <Story, List<Story>>{};
      final tasks = getTasksForActivity(activity.id);
      
      for (final task in tasks) {
        taskMap[task] = getStoriesForTask(task.id);
      }
      
      hierarchy[activity] = taskMap;
    }
    
    return hierarchy;
  }

  /// 按发布阶段分组故事
  Map<ReleasePhase, List<Story>> groupByPhase() {
    final grouped = <ReleasePhase, List<Story>>{};
    for (final story in stories) {
      grouped.putIfAbsent(story.phase, () => []).add(story);
    }
    return grouped;
  }

  /// 根据ID查找故事
  Story? findById(String id) {
    try {
      return _stories.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 获取故事的完整路径（从根到当前故事）
  List<Story> getPathToStory(String storyId) {
    final path = <Story>[];
    Story? current = findById(storyId);
    
    while (current != null) {
      path.insert(0, current);
      current = current.parentId != null ? findById(current.parentId!) : null;
    }
    
    return path;
  }
}

// ============= 兼容层：旧模型转换 =============
/// 提供与旧三层模型的兼容转换
class LegacyConverter {
  /// 从旧的StoryMap转换为新的Story列表
  static List<Story> fromLegacyStoryMap(Map<String, dynamic> json) {
    final stories = <Story>[];
    final storyMap = json['storyMap'] as Map<String, dynamic>? ?? {};
    final activities = storyMap['activities'] as List<dynamic>? ?? [];
    
    for (final activityJson in activities) {
      final activity = activityJson as Map<String, dynamic>;
      final activityId = activity['id'] as String;
      
      // 添加活动
      stories.add(Story(
        id: activityId,
        title: activity['title'] as String,
        level: StoryLevel.activity,
        order: activity['order'] as int? ?? 0,
        color: activity['color'] as String?,
        phase: ReleasePhase.mvp,
        status: StoryStatus.done,
      ));
      
      final tasks = activity['tasks'] as List<dynamic>? ?? [];
      for (final taskJson in tasks) {
        final task = taskJson as Map<String, dynamic>;
        final taskId = task['id'] as String;
        
        // 添加任务
        stories.add(Story(
          id: taskId,
          title: task['title'] as String,
          level: StoryLevel.task,
          parentId: activityId,
          order: task['order'] as int? ?? 0,
          phase: ReleasePhase.mvp,
          status: StoryStatus.done,
        ));
        
        final storyList = task['stories'] as List<dynamic>? ?? [];
        for (final storyJson in storyList) {
          final storyData = storyJson as Map<String, dynamic>;
          
          // 添加故事
          stories.add(Story(
            id: storyData['id'] as String,
            title: storyData['title'] as String,
            description: storyData['description'] as String?,
            level: StoryLevel.story,
            parentId: taskId,
            phase: ReleasePhase.values.byName(storyData['phase'] as String),
            status: StoryStatus.values.byName(storyData['status'] as String),
          ));
        }
      }
    }
    
    return stories;
  }
  
  /// 转换为旧的StoryMap格式（用于兼容现有JSON）
  static Map<String, dynamic> toLegacyStoryMap(List<Story> stories) {
    final repo = StoryRepository(stories);
    final activities = repo.activities;
    
    final legacyActivities = <dynamic>[];
    for (final activity in activities) {
      final tasks = repo.getTasksForActivity(activity.id);
      final legacyTasks = <dynamic>[];
      
      for (final task in tasks) {
        final storyList = repo.getStoriesForTask(task.id);
        final legacyStories = storyList.map((s) => {
          'id': s.id,
          'title': s.title,
          if (s.description != null) 'description': s.description,
          'phase': s.phase.name,
          'status': s.status.name,
        }).toList();
        
        legacyTasks.add({
          'id': task.id,
          'title': task.title,
          'activityId': activity.id,
          'order': task.order,
          'stories': legacyStories,
        });
      }
      
      legacyActivities.add({
        'id': activity.id,
        'title': activity.title,
        'order': activity.order,
        if (activity.color != null) 'color': activity.color,
        'tasks': legacyTasks,
      });
    }
    
    return {
      'id': 'map-product',
      'name': 'qtcloud-product',
      'mvpLinePosition': 0.4,
      'activities': legacyActivities,
    };
  }
}

// ============= 旧模型兼容层 =============
/// 用于兼容旧JSON格式的StoryMap类
class StoryMap {
  final String id;
  final String name;
  final double mvpLinePosition;
  final List<Map<String, dynamic>> activities; // 保留原始活动数据

  const StoryMap({
    required this.id,
    required this.name,
    this.mvpLinePosition = 0.33,
    this.activities = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mvpLinePosition': mvpLinePosition,
    'activities': activities,
  };

  factory StoryMap.fromJson(Map<String, dynamic> json) {
    return StoryMap(
      id: json['id'] as String,
      name: json['name'] as String,
      mvpLinePosition: (json['mvpLinePosition'] as num?)?.toDouble() ?? 0.33,
      activities: (json['activities'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}