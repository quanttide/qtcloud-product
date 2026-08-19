import 'package:flutter/material.dart';

import '../models/event_storm_models.dart';
import '../widgets/event_storming_canvas.dart';

/// 规格屏：事件风暴
///
/// 数据驱动的事件流时间线：领域事件按时间顺序展开，
/// 点击事件查看触发命令、参与者、聚合、策略等规格详情。
class SpecificationScreen extends StatelessWidget {
  const SpecificationScreen({super.key, this.eventStorm});

  /// 产品的事件风暴数据（种子数据 eventStorm 字段）
  final EventStorming? eventStorm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 22,
                color: Color(0xFF37474F),
              ),
              const SizedBox(width: 10),
              const Text(
                '规格（事件风暴）',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF37474F),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '事件流时间线：领域事件（Domain Event）按时间顺序展开，'
                  '点击事件查看命令 / 聚合 / 策略 / 参与者关联',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: EventStormingCanvas(eventStorm: eventStorm)),
      ],
    );
  }
}
