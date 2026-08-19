import 'package:flutter/material.dart';

import '../models/acceptance_models.dart';
import '../models/story_map_models.dart';

/// 验收筛选
enum _AcceptanceFilter {
  all('全部'),
  pending('未验收'),
  passed('通过'),
  failed('失败');

  final String label;

  const _AcceptanceFilter(this.label);

  bool matches(AcceptanceStatus status) => switch (this) {
        _AcceptanceFilter.all => true,
        _AcceptanceFilter.pending => status == AcceptanceStatus.pending,
        _AcceptanceFilter.passed => status == AcceptanceStatus.passed,
        _AcceptanceFilter.failed => status == AcceptanceStatus.failed,
      };
}

/// 验收清单：交付门禁
///
/// 数据源为验收项（AcceptanceItem，挂在用户故事下），按故事分组展示；
/// 每项验证一条交付标准（需求验收 / 事件风暴异常场景派生），点击循环切换
/// 未验收 → 通过 → 失败；失败项记录原因（打回开发依据）。MVP 为内存态。
class AcceptanceScreen extends StatefulWidget {
  const AcceptanceScreen({
    super.key,
    required this.acceptances,
    required this.stories,
  });

  /// 验收项（看板数据）
  final List<AcceptanceItem> acceptances;

  /// 用户故事（解析验收项所属故事标题与分组顺序）
  final List<Story> stories;

  @override
  State<AcceptanceScreen> createState() => _AcceptanceScreenState();
}

class _AcceptanceScreenState extends State<AcceptanceScreen> {
  late List<AcceptanceItem> _items;
  _AcceptanceFilter _filter = _AcceptanceFilter.all;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.acceptances);
  }

  @override
  void didUpdateWidget(AcceptanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.acceptances != widget.acceptances) {
      _items = List.of(widget.acceptances);
    }
  }

  String _storyTitleOf(String storyId) {
    for (final story in widget.stories) {
      if (story.id == storyId) return story.title;
    }
    return storyId;
  }

  /// 点击验收项：循环切换 未验收 → 通过 → 失败 → 未验收
  void _cycleStatus(AcceptanceItem item) {
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index < 0) return;
      final next = switch (item.status) {
        AcceptanceStatus.pending => AcceptanceStatus.passed,
        AcceptanceStatus.passed => AcceptanceStatus.failed,
        AcceptanceStatus.failed => AcceptanceStatus.pending,
      };
      _items[index] = item.copyWith(
        status: next,
        note: next == AcceptanceStatus.failed
            ? (item.note ?? '验收未通过，已退回开发')
            : null,
      );
    });
  }

  // ============ 统计 ============

  int get _total => _items.length;
  int get _passed => _items.where((i) => i.status == AcceptanceStatus.passed).length;
  int get _failed => _items.where((i) => i.status == AcceptanceStatus.failed).length;
  int get _pending => _items.where((i) => i.status == AcceptanceStatus.pending).length;

  double get _passRate => _total == 0 ? 0 : _passed / _total;

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const _EmptyState();
    }
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummary(),
          const SizedBox(height: 10),
          _buildFilters(),
          const SizedBox(height: 10),
          Expanded(child: _buildGroupedList()),
        ],
      ),
    );
  }

  // ============ 顶部统计 ============

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // 通过率圆环
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _passRate,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF388E3C)),
                ),
                Center(
                  child: Text(
                    '${(_passRate * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF37474F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _SummaryBlock(
                  key: const Key('stat-total'),
                  label: '全部',
                  count: _total,
                  color: const Color(0xFF37474F),
                ),
                _SummaryBlock(
                  key: const Key('stat-passed'),
                  label: '通过',
                  count: _passed,
                  color: const Color(0xFF388E3C),
                ),
                _SummaryBlock(
                  key: const Key('stat-failed'),
                  label: '失败',
                  count: _failed,
                  color: const Color(0xFFD32F2F),
                ),
                _SummaryBlock(
                  key: const Key('stat-pending'),
                  label: '未验收',
                  count: _pending,
                  color: const Color(0xFF9E9E9E),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '点击验收项切换：未验收 → 通过 → 失败',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ============ 筛选 ============

  Widget _buildFilters() {
    return Row(
      children: [
        for (final filter in _AcceptanceFilter.values) ...[
          _FilterPill(
            key: Key('filter-${filter.name}'),
            label: filter.label,
            selected: _filter == filter,
            onTap: () => setState(() => _filter = filter),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ============ 分组列表 ============

  Widget _buildGroupedList() {
    // 故事顺序（用于分组排序）
    final storyOrder = <String, int>{
      for (var i = 0; i < widget.stories.length; i++)
        widget.stories[i].id: i,
    };
    // 按筛选条件过滤
    final visible = _items.where((i) => _filter.matches(i.status)).toList();
    // 按故事分组
    final groups = <String, List<AcceptanceItem>>{};
    for (final item in visible) {
      groups.putIfAbsent(item.storyId, () => []).add(item);
    }
    final sortedStoryIds = groups.keys.toList()
      ..sort((a, b) => (storyOrder[a] ?? 999).compareTo(storyOrder[b] ?? 999));

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedStoryIds.length,
      itemBuilder: (context, index) {
        final storyId = sortedStoryIds[index];
        return _StoryGroup(
          storyTitle: _storyTitleOf(storyId),
          storyId: storyId,
          items: groups[storyId]!,
          allItems: _items.where((i) => i.storyId == storyId).toList(),
          onTapItem: _cycleStatus,
        );
      },
    );
  }
}

// ============ 统计块 ============

class _SummaryBlock extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryBlock({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ============ 筛选 pill ============

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2C3E50) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF2C3E50) : Colors.grey[400]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF37474F),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ 故事分组 ============

class _StoryGroup extends StatelessWidget {
  final String storyId;
  final String storyTitle;

  /// 当前筛选下的可见验收项
  final List<AcceptanceItem> items;

  /// 该故事的全部验收项（组头进度基于全量，不受筛选影响）
  final List<AcceptanceItem> allItems;

  final ValueChanged<AcceptanceItem> onTapItem;

  const _StoryGroup({
    required this.storyId,
    required this.storyTitle,
    required this.items,
    required this.allItems,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final passed = allItems.where((i) => i.status == AcceptanceStatus.passed).length;
    return Container(
      key: Key('acceptance-group-$storyId'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 组头：故事标题 + 进度
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 15, color: Color(0xFF546E7A)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    storyTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF37474F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '通过 $passed/${allItems.length}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // 验收项列表
          for (final item in items) _AcceptanceRow(item: item, onTap: () => onTapItem(item)),
        ],
      ),
    );
  }
}

// ============ 验收项行 ============

class _AcceptanceRow extends StatelessWidget {
  final AcceptanceItem item;
  final VoidCallback onTap;

  const _AcceptanceRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.status) {
      AcceptanceStatus.passed => (Icons.check_circle, const Color(0xFF388E3C)),
      AcceptanceStatus.failed => (Icons.cancel, const Color(0xFFD32F2F)),
      AcceptanceStatus.pending => (Icons.radio_button_unchecked, const Color(0xFF9E9E9E)),
    };
    final isSpec = item.source == AcceptanceSource.spec;

    return InkWell(
      key: Key('acceptance-item-${item.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF37474F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // 来源徽标：需求验收 / 异常场景（规格验收）
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSpec
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.source.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSpec
                                ? const Color(0xFFE65100)
                                : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      if (item.note != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '原因：${item.note}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD32F2F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ 空态 ============

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fact_check_outlined, size: 42, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            '暂无验收项',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '开发完成后，在此逐项验证交付成果是否符合需求与规格',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
