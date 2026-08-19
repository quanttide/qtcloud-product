/// 事件风暴（Event Storming）领域模型
///
/// 规格模块的数据模型：以时间线顺序的领域事件（Domain Event）为核心，
/// 关联命令（Command）、参与者（Actor）、聚合（Aggregate）、策略（Policy）、
/// 外部系统（External System）与查询模型（Query Model）。
///
/// 与用户故事地图（Story）一致：模型是唯一事实源，渲染前投影，不做数据变更。
library;

/// 事件风暴节点类型
enum StormNodeType {
  actor('Actor'),
  command('Command / Action'),
  event('Domain Event'),
  policy('Policy'),
  aggregate('Aggregate'),
  externalSystem('External System'),
  queryModel('Query Model / Information'),
  hotspot('Hotspot');

  final String label;

  const StormNodeType(this.label);

  static StormNodeType fromJson(String value) =>
      StormNodeType.values.firstWhere((t) => t.name == value);
}

/// 事件风暴节点（统一模型，type 区分角色）
class StormNode {
  final String id;
  final StormNodeType type;
  final String title;
  final String? description;

  /// 时间线顺序（对事件有意义；其余节点为 0）
  final int order;

  /// 命令的发起者 / 事件的触发者（Actor id）
  final String? actorId;

  /// 事件的触发命令（Command id）
  final String? commandId;

  /// 事件所属聚合（Aggregate id）
  final String? aggregateId;

  /// 事件激活的策略（Policy id 列表）
  final List<String> policyIds;

  /// 事件产出的查询模型（Query Model id）
  final String? queryModelId;

  /// 命令调用的外部系统（External System id）
  final String? externalSystemId;

  /// 是否异常事件（失败 / 回滚 / 被拒等非正常流程；事件风暴中异常与正常同等重要）
  final bool isException;

  /// 异常事件分岔自哪个主线事件（Event id；正常事件为 null）
  final String? fromEventId;

  const StormNode({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.order = 0,
    this.actorId,
    this.commandId,
    this.aggregateId,
    this.policyIds = const [],
    this.queryModelId,
    this.externalSystemId,
    this.isException = false,
    this.fromEventId,
  });

  bool get isEvent => type == StormNodeType.event;
  bool get isCommand => type == StormNodeType.command;
  bool get isActor => type == StormNodeType.actor;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        if (description != null) 'description': description,
        if (order != 0) 'order': order,
        if (actorId != null) 'actorId': actorId,
        if (commandId != null) 'commandId': commandId,
        if (aggregateId != null) 'aggregateId': aggregateId,
        if (policyIds.isNotEmpty) 'policyIds': policyIds,
        if (queryModelId != null) 'queryModelId': queryModelId,
        if (externalSystemId != null) 'externalSystemId': externalSystemId,
        if (isException) 'isException': true,
        if (fromEventId != null) 'fromEventId': fromEventId,
      };

  factory StormNode.fromJson(Map<String, dynamic> json) {
    return StormNode(
      id: json['id'] as String,
      type: StormNodeType.fromJson(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      actorId: json['actorId'] as String?,
      commandId: json['commandId'] as String?,
      aggregateId: json['aggregateId'] as String?,
      policyIds: (json['policyIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      queryModelId: json['queryModelId'] as String?,
      externalSystemId: json['externalSystemId'] as String?,
      isException: json['isException'] as bool? ?? false,
      fromEventId: json['fromEventId'] as String?,
    );
  }
}

/// 产品的事件风暴（规格）
class EventStorming {
  final String id;

  /// 产品唯一命名（与 Product.name 一致）
  final String productId;

  final String title;

  /// 规格思路说明
  final String? description;

  /// 全部节点（事件 / 命令 / 参与者 / 聚合 / 策略 ...）
  final List<StormNode> nodes;

  const EventStorming({
    required this.id,
    required this.productId,
    required this.title,
    this.description,
    this.nodes = const [],
  });

  /// 主线事件（非异常，按 order 升序）
  List<StormNode> get mainlineEvents =>
      nodes.where((n) => n.isEvent && !n.isException).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// 异常事件（按 order 升序）
  List<StormNode> get exceptions =>
      nodes.where((n) => n.isEvent && n.isException).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// 从某主线事件分岔出去的异常事件
  List<StormNode> exceptionsOf(StormNode mainEvent) => [
        for (final n in exceptions)
          if (n.fromEventId == mainEvent.id) n,
      ];

  /// 事件分岔自的主线事件（无则 null）
  StormNode? sourceEventOf(StormNode exception) =>
      exception.fromEventId == null ? null : nodeById(exception.fromEventId!);

  /// 按 id 查找节点
  StormNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// 事件触发的命令（无则 null）
  StormNode? commandOf(StormNode event) =>
      event.commandId == null ? null : nodeById(event.commandId!);

  /// 事件所属聚合（无则 null）
  StormNode? aggregateOf(StormNode event) =>
      event.aggregateId == null ? null : nodeById(event.aggregateId!);

  /// 事件的触发者（Actor，无则 null）
  StormNode? actorOf(StormNode event) =>
      event.actorId == null ? null : nodeById(event.actorId!);

  /// 事件激活的策略列表
  List<StormNode> policiesOf(StormNode event) => [
        for (final id in event.policyIds)
          if (nodeById(id) != null) nodeById(id)!,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'title': title,
        if (description != null) 'description': description,
        'nodes': [for (final node in nodes) node.toJson()],
      };

  factory EventStorming.fromJson(Map<String, dynamic> json) {
    return EventStorming(
      id: json['id'] as String,
      productId: json['productId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      nodes: (json['nodes'] as List<dynamic>? ?? const [])
          .map((e) => StormNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
