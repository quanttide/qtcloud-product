// 验收模块的领域模型
//
// 验收 = 交付门禁：开发完成后，逐项验证交付成果是否符合
// 需求（用户故事）与规格（事件风暴），通过的才算真正完成，失败的打回开发。

// ============= 验收状态枚举 =============
enum AcceptanceStatus {
  pending('未验收'),
  passed('通过'),
  failed('失败');

  final String label;

  const AcceptanceStatus(this.label);
}

// ============= 验收项来源枚举 =============
enum AcceptanceSource {
  /// 需求验收：从用户故事提炼的验收标准
  story('需求验收'),

  /// 规格验收：从事件风暴（异常事件）派生的异常场景验收
  spec('异常场景');

  final String label;

  const AcceptanceSource(this.label);
}

// ============= 验收项模型 =============
/// 验收项（Acceptance Item）
///
/// 挂在用户故事下（[storyId]），描述一条可验证的验收标准；
/// 来源为需求验收（从用户故事提炼）或规格验收（从事件风暴异常事件派生，
/// 以 [eventId] 关联事件节点，实现 规格 → 验收 可追溯）。
class AcceptanceItem {
  final String id;
  final String title; // 验收标准描述

  /// 关联用户故事 id（验收对象 = 用户故事级）
  final String storyId;

  final AcceptanceSource source;

  /// 规格验收时关联的事件风暴事件节点 id（异常事件）
  final String? eventId;

  final AcceptanceStatus status;

  /// 失败原因 / 备注（验收失败时记录，展示"打回开发"依据）
  final String? note;

  const AcceptanceItem({
    required this.id,
    required this.title,
    required this.storyId,
    this.source = AcceptanceSource.story,
    this.eventId,
    this.status = AcceptanceStatus.pending,
    this.note,
  });

  AcceptanceItem copyWith({
    String? id,
    String? title,
    String? storyId,
    AcceptanceSource? source,
    String? eventId,
    AcceptanceStatus? status,
    String? note,
  }) {
    return AcceptanceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      storyId: storyId ?? this.storyId,
      source: source ?? this.source,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'storyId': storyId,
        'source': source.name,
        if (eventId != null) 'eventId': eventId,
        'status': status.name,
        if (note != null) 'note': note,
      };

  factory AcceptanceItem.fromJson(Map<String, dynamic> json) {
    return AcceptanceItem(
      id: json['id'] as String,
      title: json['title'] as String,
      storyId: json['storyId'] as String,
      source: AcceptanceSource.values.byName(json['source'] as String),
      eventId: json['eventId'] as String?,
      status: AcceptanceStatus.values.byName(json['status'] as String),
      note: json['note'] as String?,
    );
  }
}
