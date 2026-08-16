import '../models/product_models.dart';
import '../models/story_map_models.dart';

/// 种子数据：第一批实验产品的用户故事地图
///
/// 每个产品的故事地图呈现其设计思路：
/// - qtcloud-devops：严格按照 DevOps 八步流程设计，在故事地图上聚合为四个阶段
///   （📋 计划与状态 → 💻 开发编码 → ✅ 测试与验证 → 🚀 正式发布）
/// - qtcloud-product：以故事地图显式化产品结构，用组合视图支撑多产品决策
/// - qtcloud-code：3R 人机协作（Review → Reflect → Refactor），规则引擎把关、人做决策
///
/// 叙事约定：故事卡片标题使用动词开头的用户语言（"做什么"），
/// 具体命令与技术细节放入 description 第二层。

/// 种子数据：第一批实验产品（qtcloud-devops / qtcloud-product / qtcloud-code）
final List<Product> seedProducts = [
  _qtcloudDevops(),
  _qtcloudProduct(),
  _qtcloudCode(),
];

// ============ qtcloud-devops：量潮 DevOps 云 ============
// 设计思路：严格按照 DevOps 八步流程设计（了解当前状态 → 同步子模块 → 开发 →
// 预发布验证 → CI 验证 → 正式发布 → 验证发布 → 维护），
// 在故事地图上聚合为四个阶段，每个阶段以可执行命令落地，约束结果而非行为。

Product _qtcloudDevops() {
  return const Product(
    id: 'qtcloud-devops',
    name: 'qtcloud-devops',
    tagline: '把发布规范封装成 CLI，八步流程驱动价值流动',
    designIdea: '严格按照 DevOps 八步流程设计，在故事地图上聚合为四个阶段：计划与状态 → 开发编码 → 测试与验证 → 正式发布。每个阶段以可执行命令落地（code status / sync，release stage / publish / retire），约束结果而非行为。',
    storyMap: StoryMap(
      id: 'map-devops',
      name: 'qtcloud-devops',
      mvpLinePosition: 0.55,
      activities: [
        // 阶段一：计划与状态（八步流程 Step 1-2）
        UserActivity(
          id: 'devops-phase-1',
          title: '📋 计划与状态',
          order: 0,
          tasks: [
            UserTask(
              id: 'devops-task-status',
              title: '了解当前状态',
              activityId: 'devops-phase-1',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-1',
                  title: '查看迭代计划与待办',
                  description: 'ROADMAP / BUGS / TODO',
                  taskId: 'devops-task-status',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'devops-story-2',
                  title: '了解子模块状态',
                  description: 'qtcloud-devops code status',
                  taskId: 'devops-task-status',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-sync',
              title: '同步子模块',
              activityId: 'devops-phase-1',
              order: 1,
              stories: [
                UserStory(
                  id: 'devops-story-3',
                  title: '同步代码仓库',
                  description: 'code sync：推送 → 更新父指针 → 推送父仓库',
                  taskId: 'devops-task-sync',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-audit',
              title: '审查代码质量',
              activityId: 'devops-phase-1',
              order: 2,
              stories: [
                UserStory(
                  id: 'devops-story-4',
                  title: '进行代码质量审查',
                  description: 'code audit --json',
                  taskId: 'devops-task-audit',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-5',
                  title: '从审计自动生成规划',
                  description: 'todo / roadmap-from-audit 流水线',
                  taskId: 'devops-task-audit',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        // 阶段二：开发编码（八步流程 Step 3）
        UserActivity(
          id: 'devops-phase-2',
          title: '💻 开发编码',
          order: 1,
          tasks: [
            UserTask(
              id: 'devops-task-develop',
              title: '编写并测试代码',
              activityId: 'devops-phase-2',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-6',
                  title: '修改代码并保证测试通过',
                  description: 'cargo test（含 cli / code / release 集成测试）',
                  taskId: 'devops-task-develop',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
          ],
        ),
        // 阶段三：测试与验证（八步流程 Step 4-5）
        UserActivity(
          id: 'devops-phase-3',
          title: '✅ 测试与验证',
          order: 2,
          tasks: [
            UserTask(
              id: 'devops-task-preflight',
              title: '预发布验证',
              activityId: 'devops-phase-3',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-7',
                  title: '检查版本一致性',
                  description: 'preflight.sh',
                  taskId: 'devops-task-preflight',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-8',
                  title: '标记预发布版本',
                  description: 'release stage -v cli/v0.4.1-rc.1 触发 CI',
                  taskId: 'devops-task-preflight',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-ci',
              title: 'CI 验证',
              activityId: 'devops-phase-3',
              order: 1,
              stories: [
                UserStory(
                  id: 'devops-story-9',
                  title: '等待构建与测试通过',
                  description: 'CI 完成后进入下一步',
                  taskId: 'devops-task-ci',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-10',
                  title: '随时查看发布状态',
                  description: 'release status',
                  taskId: 'devops-task-ci',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
          ],
        ),
        // 阶段四：正式发布（八步流程 Step 6-8）
        UserActivity(
          id: 'devops-phase-4',
          title: '🚀 正式发布',
          order: 3,
          tasks: [
            UserTask(
              id: 'devops-task-publish',
              title: '正式发布',
              activityId: 'devops-phase-4',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-11',
                  title: '发布软件版本',
                  description: 'release publish -v cli/v0.4.1 -y',
                  taskId: 'devops-task-publish',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-12',
                  title: '自动分发到注册源',
                  description: 'CI 推送 crates.io 与 PyPI',
                  taskId: 'devops-task-publish',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-verify',
              title: '验证发布',
              activityId: 'devops-phase-4',
              order: 1,
              stories: [
                UserStory(
                  id: 'devops-story-13',
                  title: '确认发布成功',
                  description: 'release status；cargo search / pip install 验证',
                  taskId: 'devops-task-verify',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-retire',
              title: '维护',
              activityId: 'devops-phase-4',
              order: 2,
              stories: [
                UserStory(
                  id: 'devops-story-14',
                  title: '退役过时版本',
                  description: 'release retire -v v0.3.0',
                  taskId: 'devops-task-retire',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'devops-story-15',
                  title: '退役废弃子模块',
                  description: 'code retire',
                  taskId: 'devops-task-retire',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

// ============ qtcloud-product：量潮产品云 ============

Product _qtcloudProduct() {
  return const Product(
    id: 'qtcloud-product',
    name: 'qtcloud-product',
    tagline: '集中管理和可视化所有产品，支撑产品决策',
    designIdea: '以用户故事地图（用户活动 → 用户任务 → 用户故事）显式化单产品结构，以 MVP 发布线划定版本边界；产品越来越多、决策越来越难，向上生长出产品组合视图：产品目录、跨产品可视化与可追溯的决策记录。',
    storyMap: StoryMap(
      id: 'map-product',
      name: 'qtcloud-product',
      mvpLinePosition: 0.4,
      activities: [
        UserActivity(
          id: 'product-stories',
          title: '管理用户故事',
          order: 0,
          tasks: [
            UserTask(
              id: 'product-task-map',
              title: '维护故事地图',
              activityId: 'product-stories',
              order: 0,
              stories: [
                UserStory(
                  id: 'product-story-1',
                  title: '建立产品全景骨架',
                  description: '用户活动分组（UserActivity）',
                  taskId: 'product-task-map',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'product-story-2',
                  title: '拆解任务与故事',
                  description: '用户任务 → 用户故事',
                  taskId: 'product-task-map',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
            UserTask(
              id: 'product-task-story',
              title: '细化用户故事',
              activityId: 'product-stories',
              order: 1,
              stories: [
                UserStory(
                  id: 'product-story-3',
                  title: '编辑用户故事',
                  description: '3C 或验收标准两种格式',
                  taskId: 'product-task-story',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'product-story-4',
                  title: '对比两种故事格式',
                  description: '对话式 vs 富文本式',
                  taskId: 'product-task-story',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
          ],
        ),
        UserActivity(
          id: 'product-roadmap',
          title: '制定版本计划',
          order: 1,
          tasks: [
            UserTask(
              id: 'product-task-mvp',
              title: '划定 MVP 边界',
              activityId: 'product-roadmap',
              order: 0,
              stories: [
                UserStory(
                  id: 'product-story-5',
                  title: '拖动发布线划定版本范围',
                  description: 'MVP 发布线（Release Line）',
                  taskId: 'product-task-mvp',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'product-story-6',
                  title: '区分 MVP 与未来迭代',
                  description: '版本边界清晰可见',
                  taskId: 'product-task-mvp',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
            UserTask(
              id: 'product-task-version',
              title: '对齐版本节奏',
              activityId: 'product-roadmap',
              order: 1,
              stories: [
                UserStory(
                  id: 'product-story-7',
                  title: '对齐各产品版本节奏',
                  description: '版本计划关联路线图',
                  taskId: 'product-task-version',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        UserActivity(
          id: 'product-portfolio',
          title: '管理产品组合',
          order: 2,
          tasks: [
            UserTask(
              id: 'product-task-catalog',
              title: '登记产品目录',
              activityId: 'product-portfolio',
              order: 0,
              stories: [
                UserStory(
                  id: 'product-story-8',
                  title: '登记产品与负责人',
                  description: '产品状态可追踪',
                  taskId: 'product-task-catalog',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'product-story-9',
                  title: '接入第一批实验对象',
                  description: 'qtcloud-devops / qtcloud-product / qtcloud-code',
                  taskId: 'product-task-catalog',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'product-task-portfolio',
              title: '查看组合视图',
              activityId: 'product-portfolio',
              order: 1,
              stories: [
                UserStory(
                  id: 'product-story-10',
                  title: '跨产品可视化对比',
                  description: '成熟度、投入、版本时间线',
                  taskId: 'product-task-portfolio',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'product-task-decision',
              title: '记录决策',
              activityId: 'product-portfolio',
              order: 2,
              stories: [
                UserStory(
                  id: 'product-story-11',
                  title: '记录产品决策',
                  description: '决策关联产品与依据，可追溯',
                  taskId: 'product-task-decision',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

// ============ qtcloud-code：量潮编程云 ============

Product _qtcloudCode() {
  return const Product(
    id: 'qtcloud-code',
    name: 'qtcloud-code',
    tagline: '3R 人机协作：规则引擎把关，人做决策',
    designIdea: '遵循高级程序员的工作范式：Review（规则引擎第一道扫描，快、确定、无遗漏）→ Reflect（根因追溯在人脑，工具提供 trace/graph/suggest 证据）→ Refactor（重构决策在人脑，工具执行 rename 等修改并支持 --dry-run 预览），以契约校验收口。',
    storyMap: StoryMap(
      id: 'map-code',
      name: 'qtcloud-code',
      mvpLinePosition: 0.5,
      activities: [
        UserActivity(
          id: 'code-review',
          title: '审查代码',
          order: 0,
          tasks: [
            UserTask(
              id: 'code-task-lint',
              title: '运行规则引擎',
              activityId: 'code-review',
              order: 0,
              stories: [
                UserStory(
                  id: 'code-story-1',
                  title: '扫描多语言代码',
                  description: '5 语言解析：Rust / Python / Go / Dart / TS',
                  taskId: 'code-task-lint',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'code-story-2',
                  title: '发现代码问题',
                  description: '5 类检测器：过长函数 / unsafe / 过长参数 / 未使用变量 / 缺失测试',
                  taskId: 'code-task-lint',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
            UserTask(
              id: 'code-task-mode',
              title: '选择协作模式',
              activityId: 'code-review',
              order: 1,
              stories: [
                UserStory(
                  id: 'code-story-3',
                  title: '仅规则引擎快速扫描',
                  description: '--mode lint，秒级',
                  taskId: 'code-task-mode',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'code-story-4',
                  title: '规则引擎 + AI 审查',
                  description: '--mode llm，默认模式',
                  taskId: 'code-task-mode',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'code-story-5',
                  title: 'AI 辅助自动修复',
                  description: '--mode deep，需人工审核',
                  taskId: 'code-task-mode',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        UserActivity(
          id: 'code-reflect',
          title: '反思根因',
          order: 1,
          tasks: [
            UserTask(
              id: 'code-task-trace',
              title: '追溯调用链',
              activityId: 'code-reflect',
              order: 0,
              stories: [
                UserStory(
                  id: 'code-story-6',
                  title: '追溯问题调用链',
                  description: 'reflect trace',
                  taskId: 'code-task-trace',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'code-story-7',
                  title: '提取代码切片',
                  description: 'reflect slice',
                  taskId: 'code-task-trace',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'code-task-graph',
              title: '生成依赖视图',
              activityId: 'code-reflect',
              order: 1,
              stories: [
                UserStory(
                  id: 'code-story-8',
                  title: '生成依赖关系图',
                  description: 'reflect graph',
                  taskId: 'code-task-graph',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'code-story-9',
                  title: '获取修改建议',
                  description: 'reflect suggest',
                  taskId: 'code-task-graph',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        UserActivity(
          id: 'code-refactor',
          title: '执行重构',
          order: 2,
          tasks: [
            UserTask(
              id: 'code-task-rename',
              title: '重命名符号',
              activityId: 'code-refactor',
              order: 0,
              stories: [
                UserStory(
                  id: 'code-story-10',
                  title: '安全重命名符号',
                  description: 'refactor rename，符号表分析',
                  taskId: 'code-task-rename',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'code-story-11',
                  title: '预览重构改动',
                  description: '--dry-run 预览写入',
                  taskId: 'code-task-rename',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'code-story-12',
                  title: '写入重构结果',
                  description: '实际文件写入',
                  taskId: 'code-task-rename',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'code-task-contract',
              title: '校验契约',
              activityId: 'code-refactor',
              order: 1,
              stories: [
                UserStory(
                  id: 'code-story-13',
                  title: '校验代码契约',
                  description: 'contract init / list / validate',
                  taskId: 'code-task-contract',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
