import 'package:flutter/material.dart';

import '../models/operations_models.dart';
import '../models/story_map_models.dart';

/// 运营 Tab
enum _OpsTab {
  thoughts('维护者反思'),
  feedback('用户反馈');

  final String label;

  const _OpsTab(this.label);
}

/// 运营：产品上线后的观测与回流
///
/// 两部分内容：
/// - 维护者反思：维护者对产品运行状态的观察、判断与决策（人的信号）；
/// - 用户反馈：收集到的真实用户反馈，按类型（建议/问题/表扬）与处理状态
///   （未处理/已采纳/已转需求）管理，采纳后回流到需求。
/// 反馈状态点击循环切换（MVP 为内存态）。
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({
    super.key,
    required this.thoughts,
    required this.feedback,
    required this.stories,
  });

  /// 维护者们的反思
  final List<MaintainerThought> thoughts;

  /// 用户的反馈
  final List<UserFeedback> feedback;

  /// 用户故事（解析关联故事标题）
  final List<Story> stories;

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  _OpsTab _tab = _OpsTab.thoughts;
  late List<UserFeedback> _feedback;

  @override
  void initState() {
    super.initState();
    _feedback = List.of(widget.feedback);
  }

  @override
  void didUpdateWidget(OperationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback != widget.feedback) {
      _feedback = List.of(widget.feedback);
    }
  }

  String _storyTitleOf(String? storyId) {
    if (storyId == null) return '';
    for (final story in widget.stories) {
      if (story.id == storyId) return story.title;
    }
    return storyId;
  }

  /// 点击反馈：循环切换 未处理 → 已采纳 → 已转需求 → 未处理
  void _cycleStatus(UserFeedback item) {
    setState(() {
      final index = _feedback.indexWhere((f) => f.id == item.id);
      if (index < 0) return;
      final next = switch (item.status) {
        FeedbackStatus.open => FeedbackStatus.adopted,
        FeedbackStatus.adopted => FeedbackStatus.toRequirements,
        FeedbackStatus.toRequirements => FeedbackStatus.open,
      };
      _feedback[index] = item.copyWith(status: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabs(),
          const SizedBox(height: 10),
          Expanded(
            child: switch (_tab) {
              _OpsTab.thoughts => _buildThoughts(),
              _OpsTab.feedback => _buildFeedback(),
            },
          ),
        ],
      ),
    );
  }

  // ============ Tab 切换 ============

  Widget _buildTabs() {
    return Row(
      children: [
        for (final tab in _OpsTab.values) ...[
          _OpsTabPill(
            key: Key('ops-tab-${tab.name}'),
            label: tab.label,
            count: tab == _OpsTab.thoughts
                ? widget.thoughts.length
                : _feedback.length,
            selected: _tab == tab,
            onTap: () => setState(() => _tab = tab),
          ),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        Text(
          '采纳的反馈回流到需求，驱动下一轮迭代',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ============ 维护者反思 ============

  Widget _buildThoughts() {
    if (widget.thoughts.isEmpty) {
      return const _EmptyState(
        icon: Icons.lightbulb_outline,
        title: '暂无维护者反思',
        subtitle: '维护者对产品运行状态的观察与决策会记录在这里',
      );
    }
    // 按记录时间倒序（近似：按输入顺序倒序展示最新在前）
    final thoughts = widget.thoughts.reversed.toList();
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: thoughts.length,
      itemBuilder: (context, index) {
        final thought = thoughts[index];
        final storyTitle = _storyTitleOf(thought.storyId);
        return Container(
          key: Key('thought-${thought.id}'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thought.content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF37474F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      thought.author,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    thought.createdAt,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  if (storyTitle.isNotEmpty) ...[
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '← $storyTitle',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ 用户反馈 ============

  Widget _buildFeedback() {
    if (_feedback.isEmpty) {
      return const _EmptyState(
        icon: Icons.forum_outlined,
        title: '暂无用户反馈',
        subtitle: '收集到的真实用户反馈会出现在这里',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _feedback.length,
      itemBuilder: (context, index) {
        final item = _feedback[index];
        final storyTitle = _storyTitleOf(item.storyId);
        final (typeIcon, typeColor) = switch (item.type) {
          FeedbackType.suggestion => (Icons.lightbulb_outline, const Color(0xFF1565C0)),
          FeedbackType.issue => (Icons.error_outline, const Color(0xFFD32F2F)),
          FeedbackType.praise => (Icons.thumb_up_outlined, const Color(0xFF2E7D32)),
        };
        return Container(
          key: Key('feedback-${item.id}'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(typeIcon, size: 16, color: typeColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF37474F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 类型徽标
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    item.createdAt,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 8),
                  if (storyTitle.isNotEmpty)
                    Flexible(
                      child: Text(
                        '← $storyTitle',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  // 处理状态（点击循环切换）
                  InkWell(
                    key: Key('feedback-status-${item.id}'),
                    onTap: () => _cycleStatus(item),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(item.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(item.status),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(FeedbackStatus status) => switch (status) {
        FeedbackStatus.open => const Color(0xFF9E9E9E),
        FeedbackStatus.adopted => const Color(0xFF2E7D32),
        FeedbackStatus.toRequirements => const Color(0xFFE65100),
      };
}

// ============ Tab pill ============

class _OpsTabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _OpsTabPill({
    super.key,
    required this.label,
    required this.count,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF37474F),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ 空态 ============

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
