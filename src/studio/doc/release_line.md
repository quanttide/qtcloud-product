# Release Line 设计更新说明

**更新日期**: 2026年1月7日  
**变更类型**: 核心设计重构

---

## 📋 变更概述

将用户故事地图的分类维度从 **优先级（Priority）** 改为 **发布阶段（ReleasePhase）**。

### 之前的设计 ❌
```
优先级维度：Must Have / Should Have / Could Have
├─ 左侧标签栏：显示 MUST/SHOULD/COULD 三层
└─ 故事卡片：按优先级着色
```

### 新的设计 ✅
```
发布阶段维度：MVP 版本 / 未来迭代
├─ 可拖动的 Release Line（发布线）
├─ 上方（MVP）：绿色故事卡片
└─ 下方（Future）：蓝色故事卡片
```

---

## 🔧 技术改动

### 1. 数据模型 (`story_map_models.dart`)

**删除**：
```dart
enum StoryPriority {
  must('Must Have', 0),
  should('Should Have', 1),
  could('Could Have', 2);
}
```

**新增**：
```dart
enum ReleasePhase {
  mvp('MVP 版本'),
  future('未来迭代');
}
```

**更新 UserStory 类**：
```dart
class UserStory {
  // 之前
  final StoryPriority priority;
  
  // 现在
  final ReleasePhase phase;  // MVP 或 Future
}
```

### 2. UI 组件 (`story_card.dart`)

**颜色方案更新**：
- MVP（绿色）：`#E8F5E9` / `#27AE60`
- Future（蓝色）：`#EBF5FB` / `#3498DB`

**标签显示**：
```dart
// 之前
_buildTag(story.priority.label)  // "Must Have"

// 现在
_buildTag(story.phase.label)     // "MVP 版本"
```

### 3. 画布组件 (`story_map_canvas.dart`)

**移除**：左侧的 MUST/SHOULD/COULD 标签栏

**新增**：可拖动的 Release Line
```dart
// Release Line（发布线）
- 红色虚线（#E74C3C）
- 可垂直拖动调整位置
- 上方显示 "MVP" 标签（红色）
- 下方显示 "Future" 标签（灰色）
- 支持实时拖拽反馈（使用 GestureDetector）
```

**交互流程**：
1. 用户按住 Release Line 附近（±10px）
2. 垂直拖动调整线的位置
3. 实时更新 `mvpLinePosition`（0.0 ~ 1.0）
4. 触发 `onMVPLineMove` 回调

### 4. 示例数据 (`main.dart`)

**数据分布**：

| 模块 | 任务 | MVP | Future | 状态 |
|------|------|-----|--------|------|
| 对话 | 开始对话 | 2 | 0 | Done |
| 对话 | 采纳便签 | 2 | 0 | InProgress |
| 白板 | 挑选便签 | 2 | 0 | Done/InProgress |
| 白板 | 生成备忘 | 0 | 2 | To Do |
| 笔记 | 编辑备忘 | 0 | 3 | To Do |
| 笔记 | 发送结果 | 0 | 2 | To Do |

**Release Line 位置**：`mvpLinePosition: 0.45`（界于对话和白板之间）

---

## 🎨 视觉变化

### 新的布局结构

```
┌─────────────────────────────────────────┐
│  AppBar: "AI 协作平台用户故事地图"      │
├─────────────────────────────────────────┤
│                                          │
│  [对话]  [白板]  [笔记]                 │ MVP 版本
│  ████    ████    ----                   │
│                                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │ ← Release Line（可拖动）
│                                          │
│  [对话]  [白板]  [笔记]                 │ 未来迭代
│  ----    ████    ████                   │
│                                          │
└─────────────────────────────────────────┘
```

### 故事卡片配色

- **MVP 故事**（绿色）：✅ 已完成或进行中
- **Future 故事**（蓝色）：⭕ 待开发

---

## 🚀 使用示例

### 基础使用

```dart
StoryMapCanvasPage(
  mapData: storyMap,
  onStoryMove: (story, newTaskId) {
    // 处理故事移动
  },
  onStoryTap: (story) {
    // 处理故事点击
  },
  onMVPLineMove: (position) {
    // 处理 Release Line 拖动
    // position: 0.0 ~ 1.0（相对于画布高度）
    print('MVP Line 移动到: ${position * 100}%');
  },
)
```

### 动态更新 Release Line

```dart
// 在外部改变 Release Line 位置
final newStoryMap = storyMap.copyWith(
  mvpLinePosition: 0.6,  // 移到 60% 处
);
```

---

## ✅ 编译状态

- ✅ 零编译错误
- ✅ 所有 Dart 文件通过静态检查
- ✅ 可直接运行

---

## 🔄 向后兼容性

**破坏性变更**：
- `StoryPriority` 已删除，改为 `ReleasePhase`
- 所有使用 `priority` 的代码需改为 `phase`
- 旧版数据格式需要迁移

**迁移指南**：
```dart
// 旧数据
UserStory(..., priority: StoryPriority.must)

// 新数据
UserStory(..., phase: ReleasePhase.mvp)
```

---

## 🎯 下一步

- [ ] 实现背景网格线（CustomPaint）
- [ ] 支持Release Line 拖拽后的数据持久化
- [ ] 添加动画过渡效果
- [ ] 实现故事卡片随 Release Line 自动分类

---

**状态**: ✅ MVP 实现完成  
**最后更新**: 2026年1月7日
