import '../models/product_models.dart';
import '../models/story_map_models.dart';

/// 种子数据：第一批实验产品的用户故事地图
///
/// 每个产品的故事地图呈现其设计思路：
/// - qtcloud-devops：严格按照 DevOps 八步流程设计（了解当前状态 → 同步子模块
///   → 开发 → 预发布验证 → CI 验证 → 正式发布 → 验证发布 → 维护）
/// - qtcloud-product：以故事地图显式化产品结构，用组合视图支撑多产品决策
/// - qtcloud-code：3R 人机协作（Review → Reflect → Refactor），规则引擎把关、人做决策

/// 产品组合：第一批实验对象
final List<Product> seedPortfolio = [
  _qtcloudDevops(),
  _qtcloudProduct(),
  _qtcloudCode(),
];

// ============ qtcloud-devops：量潮 DevOps 云 ============
// 设计思路：严格按照 DevOps 八步流程设计，每个阶段以可执行命令落地
// （code status / sync / retire，release stage / publish / retire / status）

Product _qtcloudDevops() {
  return const Product(
    id: 'qtcloud-devops',
    name: 'qtcloud-devops',
    tagline: '把发布规范封装成 CLI，八步流程驱动价值流动',
    designIdea: '严格按照 DevOps 八步流程设计：了解当前状态 → 同步子模块 → 开发 → 预发布验证 → CI 验证 → 正式发布 → 验证发布 → 维护。每个阶段以可执行命令落地（code status / sync / retire，release stage / publish / status / retire），约束结果而非行为。',
    storyMap: StoryMap(
      id: 'map-devops',
      name: 'qtcloud-devops',
      mvpLinePosition: 0.6,
      activities: [
        // Step 1：了解当前状态
        UserActivity(
          id: 'devops-step-1',
          title: '了解当前状态',
          order: 0,
          tasks: [
            UserTask(
              id: 'devops-task-docs',
              title: '查看规划文档',
              activityId: 'devops-step-1',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-1',
                  title: '查看 ROADMAP / BUGS / TODO 了解迭代计划与待办',
                  taskId: 'devops-task-docs',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'devops-story-2',
                  title: '查看子模块状态（code status）',
                  taskId: 'devops-task-docs',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-audit',
              title: '审计代码质量',
              activityId: 'devops-step-1',
              order: 1,
              stories: [
                UserStory(
                  id: 'devops-story-3',
                  title: '执行 code audit --json 了解代码质量状态',
                  taskId: 'devops-task-audit',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-4',
                  title: '从审计自动生成 TODO 与 ROADMAP（todo/roadmap-from-audit）',
                  taskId: 'devops-task-audit',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        // Step 2：同步子模块
        UserActivity(
          id: 'devops-step-2',
          title: '同步子模块',
          order: 1,
          tasks: [
            UserTask(
              id: 'devops-task-sync',
              title: '同步子模块指针',
              activityId: 'devops-step-2',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-5',
                  title: 'code sync：推送 → 更新父指针 → 推送父仓库',
                  taskId: 'devops-task-sync',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
          ],
        ),
        // Step 3：开发
        UserActivity(
          id: 'devops-step-3',
          title: '开发',
          order: 2,
          tasks: [
            UserTask(
              id: 'devops-task-code',
              title: '编写代码',
              activityId: 'devops-step-3',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-6',
                  title: '在子模块内修改代码',
                  taskId: 'devops-task-code',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-test',
              title: '运行测试',
              activityId: 'devops-step-3',
              order: 1,
              stories: [
                UserStory(
                  id: 'devops-story-7',
                  title: 'cargo test 运行所有测试',
                  taskId: 'devops-task-test',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'devops-story-8',
                  title: '运行 CLI / code / release 集成测试',
                  taskId: 'devops-task-test',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
              ],
            ),
          ],
        ),
        // Step 4：预发布验证
        UserActivity(
          id: 'devops-step-4',
          title: '预发布验证',
          order: 3,
          tasks: [
            UserTask(
              id: 'devops-task-preflight',
              title: '版本一致性检查',
              activityId: 'devops-step-4',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-9',
                  title: '运行 preflight.sh 版本一致性检查',
                  taskId: 'devops-task-preflight',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
            UserTask(
              id: 'devops-task-stage',
              title: '标记预发布版本',
              activityId: 'devops-step-4',
              order: 1,
              stories: [
                UserStory(
                  id: 'devops-story-10',
                  title: 'release stage -v cli/v0.4.1-rc.1 触发 CI',
                  taskId: 'devops-task-stage',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
          ],
        ),
        // Step 5：CI 验证
        UserActivity(
          id: 'devops-step-5',
          title: 'CI 验证',
          order: 4,
          tasks: [
            UserTask(
              id: 'devops-task-ci',
              title: '等待 CI 完成',
              activityId: 'devops-step-5',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-11',
                  title: '等待 CI 完成构建和测试，确认无失败',
                  taskId: 'devops-task-ci',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-12',
                  title: '随时查看发布状态（release status）',
                  taskId: 'devops-task-ci',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
          ],
        ),
        // Step 6：正式发布
        UserActivity(
          id: 'devops-step-6',
          title: '正式发布',
          order: 5,
          tasks: [
            UserTask(
              id: 'devops-task-publish',
              title: '执行发布',
              activityId: 'devops-step-6',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-13',
                  title: 'release publish -v cli/v0.4.1 -y 正式发布',
                  taskId: 'devops-task-publish',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'devops-story-14',
                  title: 'CI 自动推送 crates.io 与 PyPI',
                  taskId: 'devops-task-publish',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        // Step 7：验证发布
        UserActivity(
          id: 'devops-step-7',
          title: '验证发布',
          order: 6,
          tasks: [
            UserTask(
              id: 'devops-task-verify',
              title: '确认发布状态',
              activityId: 'devops-step-7',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-15',
                  title: 'release status 确认发布状态',
                  taskId: 'devops-task-verify',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'devops-story-16',
                  title: 'cargo search / pip install 确认注册源',
                  taskId: 'devops-task-verify',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ],
        ),
        // Step 8：维护
        UserActivity(
          id: 'devops-step-8',
          title: '维护',
          order: 7,
          tasks: [
            UserTask(
              id: 'devops-task-retire',
              title: '退役过时内容',
              activityId: 'devops-step-8',
              order: 0,
              stories: [
                UserStory(
                  id: 'devops-story-17',
                  title: 'release retire 退役过时版本',
                  taskId: 'devops-task-retire',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'devops-story-18',
                  title: 'code retire 退役废弃子模块',
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
                  title: '建立用户活动泳道（UserActivity）',
                  taskId: 'product-task-map',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'product-story-2',
                  title: '拆解用户任务与用户故事',
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
                  title: '编辑用户故事（3C 或验收标准两种格式）',
                  taskId: 'product-task-story',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'product-story-4',
                  title: '对比展示两种用户故事格式',
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
                  title: '拖动 MVP 发布线调整版本范围',
                  taskId: 'product-task-mvp',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'product-story-6',
                  title: '区分 MVP 与未来迭代',
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
                  title: '制定版本计划并关联路线图',
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
                  title: '登记产品、状态与负责人',
                  taskId: 'product-task-catalog',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'product-story-9',
                  title: '第一批实验对象：devops / product / code',
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
                  title: '跨产品可视化：成熟度、投入、版本时间线',
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
                  title: '决策关联产品与依据，可追溯',
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
                  title: '5 语言解析（Rust / Python / Go / Dart / TS）',
                  taskId: 'code-task-lint',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'code-story-2',
                  title: '5 类检测器（过长函数 / unsafe / 过长参数 / 未使用变量 / 缺失测试）',
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
                  title: '--mode lint：仅规则引擎（秒级）',
                  taskId: 'code-task-mode',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'code-story-4',
                  title: '--mode llm：规则引擎 + LLM 审查（默认）',
                  taskId: 'code-task-mode',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'code-story-5',
                  title: '--mode deep：规则引擎 + LLM + LLM 修复（需审核）',
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
                  title: 'reflect trace：追溯调用链',
                  taskId: 'code-task-trace',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'code-story-7',
                  title: 'reflect slice：提取代码切片',
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
                  title: 'reflect graph：生成依赖图',
                  taskId: 'code-task-graph',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'code-story-9',
                  title: 'reflect suggest：获取修改建议',
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
                  title: 'refactor rename：符号表分析',
                  taskId: 'code-task-rename',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
                UserStory(
                  id: 'code-story-11',
                  title: '--dry-run 预览将要写入的修改',
                  taskId: 'code-task-rename',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
                UserStory(
                  id: 'code-story-12',
                  title: '实际文件写入',
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
                  title: 'contract init / list / validate',
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
