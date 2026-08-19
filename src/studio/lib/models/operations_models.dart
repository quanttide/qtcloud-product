// 运营模块的领域模型
//
// 运营 = 产品上线后的观测与回流，包含两部分：
// 1. 维护者们的反思（MaintainerThought）：维护者对产品运行状态的
//    观察、判断与下一步决策记录（与"用户反馈"对偶：Feedback / Reflection）；
// 2. 用户的反馈（UserFeedback）：真实用户反馈，按类型与处理状态管理。
// 采纳的反馈回流到需求，驱动下一轮迭代（数据驱动产品结构）。

// ============= 反馈类型枚举 =============
enum FeedbackType {
  suggestion('建议'),
  issue('问题'),
  praise('表扬');

  final String label;

  const FeedbackType(this.label);
}

// ============= 反馈处理状态枚举 =============
enum FeedbackStatus {
  open('未处理'),
  adopted('已采纳'),
  toRequirements('已转需求');

  final String label;

  const FeedbackStatus(this.label);
}

// ============= 维护者反思模型 =============
/// 维护者们的反思（运营观测）
///
/// 维护者（使用产品云的团队）对产品运行状态的观察、判断与决策，
/// 是"数据驱动产品结构"中人的那部分——比指标更早、更具体的信号。
/// 与"用户反馈"对偶：用户反馈（Feedback）↔ 维护者反思（Reflection）。
class MaintainerThought {
  final String id;
  final String content; // 思考内容
  final String author; // 维护者角色，如 产品经理 / 研发
  final String createdAt; // 记录时间（展示用字符串，如 5月20日）
  final String? productId; // 所属产品
  final String? storyId; // 关联用户故事（思考指向的故事）

  const MaintainerThought({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.productId,
    this.storyId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'author': author,
        'createdAt': createdAt,
        if (productId != null) 'productId': productId,
        if (storyId != null) 'storyId': storyId,
      };

  factory MaintainerThought.fromJson(Map<String, dynamic> json) {
    return MaintainerThought(
      id: json['id'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      createdAt: json['createdAt'] as String,
      productId: json['productId'] as String?,
      storyId: json['storyId'] as String?,
    );
  }
}

// ============= 用户反馈模型 =============
/// 用户的反馈
///
/// 收集到的真实用户反馈，按类型（建议/问题/表扬）与处理状态
/// （未处理/已采纳/已转需求）管理；已采纳与已转需求的反馈回流到需求。
class UserFeedback {
  final String id;
  final String content; // 反馈内容
  final FeedbackType type;
  final String createdAt; // 反馈时间（展示用字符串）
  final FeedbackStatus status;
  final String? productId; // 关联产品
  final String? storyId; // 反馈指向的用户故事（可选）

  const UserFeedback({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    this.status = FeedbackStatus.open,
    this.productId,
    this.storyId,
  });

  UserFeedback copyWith({
    String? id,
    String? content,
    FeedbackType? type,
    String? createdAt,
    FeedbackStatus? status,
    String? productId,
    String? storyId,
  }) {
    return UserFeedback(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      productId: productId ?? this.productId,
      storyId: storyId ?? this.storyId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type.name,
        'createdAt': createdAt,
        'status': status.name,
        if (productId != null) 'productId': productId,
        if (storyId != null) 'storyId': storyId,
      };

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'] as String,
      content: json['content'] as String,
      type: FeedbackType.values.byName(json['type'] as String),
      createdAt: json['createdAt'] as String,
      status: FeedbackStatus.values.byName(json['status'] as String),
      productId: json['productId'] as String?,
      storyId: json['storyId'] as String?,
    );
  }
}
