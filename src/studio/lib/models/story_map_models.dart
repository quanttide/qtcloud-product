/// 用户故事地图的领域模型
/// 该层代表了业务的本质，名字严谨、准确，符合用户故事地图的方法论

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

// ============= 第三层：用户故事 =============
/// 代表为了实现某个任务而需要开发的具体功能点或技术细节
class UserStory {
  final String id;
  final String title;
  final String taskId;
  final ReleasePhase phase;
  final StoryStatus status;
  final String? description;

  const UserStory({
    required this.id,
    required this.title,
    required this.taskId,
    this.phase = ReleasePhase.mvp,
    this.status = StoryStatus.todo,
    this.description,
  });

  // 用于创建修改后的副本
  UserStory copyWith({
    String? id,
    String? title,
    String? taskId,
    ReleasePhase? phase,
    StoryStatus? status,
    String? description,
  }) {
    return UserStory(
      id: id ?? this.id,
      title: title ?? this.title,
      taskId: taskId ?? this.taskId,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  @override
  String toString() =>
      'UserStory(id: $id, title: $title, phase: ${phase.label})';

  /// JSON 序列化（CLI 加工种子数据时使用）
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'taskId': taskId,
        'phase': phase.name,
        'status': status.name,
        if (description != null) 'description': description,
      };

  /// JSON 反序列化（Studio 加载种子数据时使用）
  factory UserStory.fromJson(Map<String, dynamic> json) {
    return UserStory(
      id: json['id'] as String,
      title: json['title'] as String,
      taskId: json['taskId'] as String,
      phase: ReleasePhase.values.byName(json['phase'] as String),
      status: StoryStatus.values.byName(json['status'] as String),
      description: json['description'] as String?,
    );
  }
}

// ============= 第二层：用户任务 =============
/// 代表用户在某个活动下为了完成目标所要执行的具体动作
/// 它是地图的"行走的骨骼"
class UserTask {
  final String id;
  final String title;
  final String activityId;
  final List<UserStory> stories;
  final int order;

  const UserTask({
    required this.id,
    required this.title,
    required this.activityId,
    this.stories = const [],
    this.order = 0,
  });

  // 用于创建修改后的副本
  UserTask copyWith({
    String? id,
    String? title,
    String? activityId,
    List<UserStory>? stories,
    int? order,
  }) {
    return UserTask(
      id: id ?? this.id,
      title: title ?? this.title,
      activityId: activityId ?? this.activityId,
      stories: stories ?? this.stories,
      order: order ?? this.order,
    );
  }

  @override
  String toString() =>
      'UserTask(id: $id, title: $title, storiesCount: ${stories.length})';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'activityId': activityId,
        'order': order,
        'stories': [for (final story in stories) story.toJson()],
      };

  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'] as String,
      title: json['title'] as String,
      activityId: json['activityId'] as String,
      order: json['order'] as int? ?? 0,
      stories: [
        for (final story in json['stories'] as List<dynamic>? ?? const [])
          UserStory.fromJson(story as Map<String, dynamic>),
      ],
    );
  }
}

// ============= 第一层：用户活动 =============
/// 代表用户为了达成目标所经历的宏观阶段
/// 它是地图的"脊柱"
class UserActivity {
  final String id;
  final String title;
  final List<UserTask> tasks;
  final int order;
  final String? color;

  const UserActivity({
    required this.id,
    required this.title,
    this.tasks = const [],
    this.order = 0,
    this.color,
  });

  // 用于创建修改后的副本
  UserActivity copyWith({
    String? id,
    String? title,
    List<UserTask>? tasks,
    int? order,
    String? color,
  }) {
    return UserActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
      order: order ?? this.order,
      color: color ?? this.color,
    );
  }

  @override
  String toString() =>
      'UserActivity(id: $id, title: $title, tasksCount: ${tasks.length})';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'order': order,
        if (color != null) 'color': color,
        'tasks': [for (final task in tasks) task.toJson()],
      };

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      order: json['order'] as int? ?? 0,
      color: json['color'] as String?,
      tasks: [
        for (final task in json['tasks'] as List<dynamic>? ?? const [])
          UserTask.fromJson(task as Map<String, dynamic>),
      ],
    );
  }
}

// ============= 顶层容器：故事地图 =============
/// 整个用户故事地图的根对象
class StoryMap {
  final String id;
  final String name;
  final List<UserActivity> activities;
  final double mvpLinePosition; // MVP 分界线位置（0.0 - 1.0）

  const StoryMap({
    required this.id,
    required this.name,
    this.activities = const [],
    this.mvpLinePosition = 0.33, // 默认 1/3 处
  });

  // 用于创建修改后的副本
  StoryMap copyWith({
    String? id,
    String? name,
    List<UserActivity>? activities,
    double? mvpLinePosition,
  }) {
    return StoryMap(
      id: id ?? this.id,
      name: name ?? this.name,
      activities: activities ?? this.activities,
      mvpLinePosition: mvpLinePosition ?? this.mvpLinePosition,
    );
  }

  @override
  String toString() =>
      'StoryMap(id: $id, name: $name, activitiesCount: ${activities.length})';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mvpLinePosition': mvpLinePosition,
        'activities': [for (final activity in activities) activity.toJson()],
      };

  factory StoryMap.fromJson(Map<String, dynamic> json) {
    return StoryMap(
      id: json['id'] as String,
      name: json['name'] as String,
      mvpLinePosition: (json['mvpLinePosition'] as num?)?.toDouble() ?? 0.33,
      activities: [
        for (final activity in json['activities'] as List<dynamic>? ?? const [])
          UserActivity.fromJson(activity as Map<String, dynamic>),
      ],
    );
  }
}
