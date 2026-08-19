import 'package:flutter/material.dart';

import '../models/event_storm_models.dart';

/// 事件风暴画布：规格（事件风暴）的渲染视图
///
/// 数据驱动的事件流时间线（种子数据 eventStorm 渲染）：
/// 领域事件按时间顺序横向展开，点击事件查看触发命令、参与者、
/// 聚合、策略等规格详情。
class EventStormingCanvas extends StatefulWidget {
  const EventStormingCanvas({super.key, this.eventStorm});

  /// 事件风暴数据（null 时显示空态）
  final EventStorming? eventStorm;

  @override
  State<EventStormingCanvas> createState() => _EventStormingCanvasState();
}

class _EventStormingCanvasState extends State<EventStormingCanvas> {
  /// 当前选中的事件（详情面板）
  String? _selectedEventId;

  EventStorming? get _storm => widget.eventStorm;

  @override
  Widget build(BuildContext context) {
    final storm = _storm;
    if (storm == null || storm.mainlineEvents.isEmpty) {
      return _EmptyState();
    }
    final events = storm.mainlineEvents;
    // 任一主线事件下存在异常分支时，加高时间线区域
    final hasBranch = events.any((e) => storm.exceptionsOf(e).isNotEmpty);
    final selected = _selectedEventId == null
        ? null
        : storm.nodeById(_selectedEventId!);

    return Container(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 场景标题与说明
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.timeline, size: 20, color: Color(0xFF37474F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storm.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        if (storm.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            storm.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 事件流时间线（双轨：主线横向展开，异常事件从对应事件分岔）
            SizedBox(
              height: hasBranch ? 258 : 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                itemCount: events.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      size: 18, color: Color(0xFF616161)),
                ),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final branches = storm.exceptionsOf(event);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EventCard(
                        event: event,
                        storm: storm,
                        selected: event.id == _selectedEventId,
                        onTap: () => setState(() {
                          _selectedEventId =
                              _selectedEventId == event.id ? null : event.id;
                        }),
                      ),
                      if (branches.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 10, top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward,
                                  size: 13, color: Color(0xFFC62828)),
                              SizedBox(width: 4),
                              Text(
                                '异常分支',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final branch in branches)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _EventCard(
                              event: branch,
                              storm: storm,
                              selected: branch.id == _selectedEventId,
                              onTap: () => setState(() {
                                _selectedEventId = _selectedEventId ==
                                        branch.id
                                    ? null
                                    : branch.id;
                              }),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
            // 详情面板
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected == null ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: selected == null
                    ? null
                    : Border.all(color: const Color(0xFFBDBDBD)),
              ),
              child: selected == null
                  ? Text(
                      '点击上方事件卡片查看规格详情',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    )
                  : _EventDetail(event: selected, storm: storm),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空态：无事件风暴数据
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined,
              size: 40, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 10),
          Text(
            '该产品暂无事件风暴规格数据',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// 事件卡片（时间线中的单个事件）
class _EventCard extends StatelessWidget {
  final StormNode event;
  final EventStorming storm;
  final bool selected;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.storm,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final command = storm.commandOf(event);
    final actor = storm.actorOf(event);
    final aggregate = storm.aggregateOf(event);
    final isException = event.isException;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 224,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isException
              ? (selected ? const Color(0xFFFFCDD2) : const Color(0xFFFFEBEE))
              : (selected ? const Color(0xFFFFE0B2) : Colors.white),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isException
                ? const Color(0xFFC62828)
                : (selected ? const Color(0xFFE65100) : const Color(0xFFBDBDBD)),
            width: isException || selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 因果链：参与者 → 触发命令（两个小标签并排）
            Row(
              children: [
                if (actor != null)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        actor.title,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4E342E),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (command != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        command.title,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (actor == null && command == null)
                  const SizedBox(height: 2),
              ],
            ),
            const SizedBox(height: 6),
            // 事件标题（异常事件：红色 + ⚠ 徽标）
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isException) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚠ 异常',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isException
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFFBF360C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 聚合（小标签）
            if (aggregate != null) ...[
              const SizedBox(height: 6),
              Text(
                '↳ ${aggregate.title}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 事件详情面板
class _EventDetail extends StatelessWidget {
  final StormNode event;
  final EventStorming storm;

  const _EventDetail({required this.event, required this.storm});

  Widget _row(IconData icon, Color color, String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label：$value',
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final command = storm.commandOf(event);
    final actor = storm.actorOf(event);
    final aggregate = storm.aggregateOf(event);
    final policies = storm.policiesOf(event);
    final queryModel = event.queryModelId == null
        ? null
        : storm.nodeById(event.queryModelId!);
    final external = event.externalSystemId == null
        ? null
        : storm.nodeById(event.externalSystemId!);

    // 命令的发起者（用户 → 命令 关系）
    final commandActor = command?.actorId == null
        ? null
        : storm.nodeById(command!.actorId!);

    // 异常事件分岔自的主线事件
    final sourceEvent = event.isException ? storm.sourceEventOf(event) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (event.isException) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  '⚠ 异常事件',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: event.isException
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFFBF360C),
                ),
              ),
            ),
          ],
        ),
        if (event.description != null) ...[
          const SizedBox(height: 4),
          Text(
            event.description!,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 8),
        // 因果链：参与者 → 命令 → 事件（异常事件标注分岔来源）
        if (sourceEvent != null)
          _row(Icons.call_split, const Color(0xFFC62828), '分岔自',
              sourceEvent.title),
        _row(Icons.person_outline, const Color(0xFFFFB300), '参与者', actor?.title),
        _row(Icons.touch_app_outlined, const Color(0xFF1976D2), '触发命令',
            command?.title),
        _row(Icons.person_pin_outlined, const Color(0xFF6D4C41), '命令发起者',
            commandActor?.title),
        _row(Icons.account_tree_outlined, const Color(0xFFFFB300), '聚合',
            aggregate?.title),
        if (policies.isNotEmpty)
          _row(Icons.gpp_good_outlined, const Color(0xFF7B1FA2), '策略',
              policies.map((p) => p.title).join('；')),
        _row(Icons.query_stats, const Color(0xFF388E3C), '查询模型',
            queryModel?.title),
        _row(Icons.language, const Color(0xFFD81B60), '外部系统', external?.title),
      ],
    );
  }
}
