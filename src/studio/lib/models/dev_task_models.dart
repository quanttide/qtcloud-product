import 'story_map_models.dart';

/// 开发任务（Dev Task）
///
/// 由用户故事经过再次分析拆解出的具体开发任务（如"实现产品登记表单"），
/// 进入开发看板按状态流转。与用户故事通过 [storyId] 关联（可追溯）。
class DevTask {
  final String id;
  final String title;

  /// 来源用户故事 id（storyMap 中的 Story.id）
  final String storyId;

  /// 看板状态（复用用户故事状态）
  final StoryStatus status;

  /// 任务说明（可选）
  final String? description;

  const DevTask({
    required this.id,
    required this.title,
    required this.storyId,
    this.status = StoryStatus.todo,
    this.description,
  });

  DevTask copyWith({
    String? id,
    String? title,
    String? storyId,
    StoryStatus? status,
    String? description,
  }) {
    return DevTask(
      id: id ?? this.id,
      title: title ?? this.title,
      storyId: storyId ?? this.storyId,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'storyId': storyId,
        'status': status.name,
        if (description != null) 'description': description,
      };

  factory DevTask.fromJson(Map<String, dynamic> json) {
    return DevTask(
      id: json['id'] as String,
      title: json['title'] as String,
      storyId: json['storyId'] as String,
      status: StoryStatus.values.byName(json['status'] as String),
      description: json['description'] as String?,
    );
  }
}
