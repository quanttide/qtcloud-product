import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';
import 'package:studio/models/acceptance_models.dart';
import 'package:studio/models/dev_task_models.dart';
import 'package:studio/models/event_storm_models.dart';
import 'package:studio/models/operations_models.dart';
import 'package:studio/models/product_models.dart';
import 'package:studio/models/story_map_models.dart';
import 'package:studio/screens/product_cloud_screen.dart';
import 'package:studio/widgets/event_storming_canvas.dart';

/// 组件测试使用内置夹具数据，不依赖 `assets/data/` 种子数据。
/// 种子数据增删产品（manifest）或修改故事内容时，本测试不受影响。
///
/// 夹具使用旧格式（StoryMap.activities 原始 Map），
/// Product 构造时经 LegacyConverter 转换为新 Story 模型。
void main() {
  late List<Product> products;

  setUp(() {
    products = _fixtureProducts();
  });

  test('内置夹具包含三个产品且各有故事地图', () {
    expect(products.length, 3);
    expect([for (final p in products) p.id], ['alpha', 'beta', 'gamma']);
    for (final product in products) {
      expect(product.storyMap.activities, isNotEmpty);
      expect(product.totalStories, greaterThan(0));
    }
  });

  testWidgets('应用打开：产品切换器 + 产品空间导航 + 需求看板矩阵', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    // 品牌 + 产品切换器（默认第一个产品 alpha）
    expect(find.text('量潮产品云'), findsOneWidget);
    expect(find.byKey(const Key('product-switcher')), findsOneWidget);

    // 前台展示产品标题，唯一命名（alpha）仅作识别副标题
    expect(find.text('测试产品甲'), findsWidgets);
    expect(find.text('alpha'), findsWidgets);

    // 产品空间侧边导航：需求 / 规格 / 开发 / 验收 / 运营
    expect(find.byKey(const Key('nav-requirements')), findsOneWidget);
    expect(find.byKey(const Key('nav-specification')), findsOneWidget);
    expect(find.byKey(const Key('nav-kanban')), findsOneWidget);
    expect(find.byKey(const Key('nav-acceptance')), findsOneWidget);
    expect(find.byKey(const Key('nav-operations')), findsOneWidget);

    // 需求看板：活动层（跨列合并）与任务层
    expect(find.text('活动甲'), findsOneWidget);
    expect(find.text('活动乙'), findsOneWidget);
    expect(find.text('任务甲一'), findsOneWidget);

    // Release 行（MVP 版本 / 未来迭代）
    expect(find.byKey(const Key('release-toggle-MVP 版本')), findsOneWidget);
    expect(find.byKey(const Key('release-toggle-未来迭代')), findsOneWidget);

    // 双层滚动条容器常显；水平方向多列必然溢出 → 拇指必渲染
    expect(find.byKey(const Key('scrollbar-vertical')), findsOneWidget);
    expect(find.byKey(const Key('scrollbar-horizontal')), findsOneWidget);
    expect(find.byKey(const Key('scrollbar-thumb-horizontal')), findsOneWidget);
  });

  testWidgets('产品切换器切换产品（每个产品一个空间）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('product-switcher')));
    await tester.pumpAndSettle();
    // 菜单项展示标题 + 唯一命名
    expect(find.text('测试产品乙'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('switch-beta')));
    await tester.pumpAndSettle();

    expect(find.text('活动丙'), findsOneWidget);
    expect(find.text('任务丙一'), findsOneWidget);
  });

  test('事件风暴模型：fromJson 解析、事件按时间线排序、关联查找', () {
    final es = EventStorming.fromJson({
      'id': 'es-test',
      'productId': 'alpha',
      'title': '测试场景',
      'description': '测试说明',
      'nodes': [
        {
          'id': 'evt-2',
          'type': 'event',
          'title': '第二事件',
          'order': 2,
          'commandId': 'cmd-2',
          'aggregateId': 'agg-2',
          'actorId': 'actor-1',
        },
        {
          'id': 'actor-1',
          'type': 'actor',
          'title': '参与者甲',
        },
        {
          'id': 'cmd-1',
          'type': 'command',
          'title': '命令一',
          'actorId': 'actor-1',
        },
        {
          'id': 'cmd-2',
          'type': 'command',
          'title': '命令二',
          'actorId': 'actor-1',
        },
        {
          'id': 'agg-2',
          'type': 'aggregate',
          'title': '聚合乙',
        },
        {
          'id': 'evt-x',
          'type': 'event',
          'title': '故事已被驳回',
          'order': 1,
          'commandId': 'cmd-1',
          'isException': true,
          'fromEventId': 'evt-1',
        },
        {
          'id': 'evt-1',
          'type': 'event',
          'title': '第一事件',
          'order': 0,
          'commandId': 'cmd-1',
          'policyIds': ['pol-1'],
        },
        {
          'id': 'pol-1',
          'type': 'policy',
          'title': '策略一',
        },
      ],
    });

    // 主线事件按 order 升序（异常事件不占主线位置）
    expect([for (final e in es.mainlineEvents) e.id], ['evt-1', 'evt-2']);
    // 异常事件单独成组，并记录分岔来源
    expect([for (final e in es.exceptions) e.id], ['evt-x']);
    expect(es.nodeById('evt-x')!.isException, isTrue);
    expect(es.exceptionsOf(es.nodeById('evt-1')!).single.id, 'evt-x');
    expect(es.sourceEventOf(es.nodeById('evt-x')!)?.id, 'evt-1');
    expect(es.nodeById('evt-1')!.isException, isFalse);
    // 关联查找
    final evt2 = es.nodeById('evt-2')!;
    expect(es.commandOf(evt2)?.title, '命令二');
    expect(es.aggregateOf(evt2)?.title, '聚合乙');
    expect(es.actorOf(evt2)?.title, '参与者甲');
    expect(es.policiesOf(es.nodeById('evt-1')!).single.title, '策略一');
    // 序列化往返
    final round = EventStorming.fromJson(es.toJson());
    expect(round.mainlineEvents.length, 2);
    expect(round.exceptions.length, 1);
    expect(round.nodeById('cmd-1')?.title, '命令一');
    expect(round.nodeById('evt-x')!.isException, isTrue);
    expect(round.nodeById('evt-x')!.fromEventId, 'evt-1');
  });

  testWidgets('产品空间内切换模块：规格（事件风暴）画布', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('nav-specification')));
    await tester.pumpAndSettle();
    expect(find.text('规格（事件风暴）'), findsOneWidget);
    // 事件风暴画布渲染（图例 + 数据驱动事件流）
    expect(find.byType(EventStormingCanvas), findsOneWidget);
    // 夹具 alpha 产品的事件流（数据驱动，含异常事件）
    expect(find.text('产品已登记'), findsOneWidget);
    expect(find.text('版本已发布'), findsOneWidget);
    expect(find.text('故事已被驳回'), findsOneWidget);
    expect(find.text('活动甲'), findsNothing);

    // 点击事件 → 详情面板（触发命令）
    await tester.ensureVisible(find.text('产品已登记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('产品已登记'));
    await tester.pumpAndSettle();
    expect(find.text('触发命令：登记产品'), findsOneWidget);

    // 点击异常事件 → 详情面板（异常标记 + 分岔来源）
    await tester.tap(find.text('故事已被驳回'));
    await tester.pumpAndSettle();
    expect(find.text('⚠ 异常事件'), findsOneWidget);
    expect(find.text('分岔自：产品已登记'), findsOneWidget);

    // 回到需求模块
    await tester.tap(find.byKey(const Key('nav-requirements')));
    await tester.pumpAndSettle();
    expect(find.text('活动甲'), findsOneWidget);
  });

  testWidgets('开发看板：状态列渲染 + 拖拽流转', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('nav-kanban')));
    await tester.pumpAndSettle();

    // 四列 + 计数
    expect(find.byKey(const Key('kanban-column-todo')), findsOneWidget);
    expect(find.byKey(const Key('kanban-column-inProgress')), findsOneWidget);
    expect(find.byKey(const Key('kanban-column-review')), findsOneWidget);
    expect(find.byKey(const Key('kanban-column-done')), findsOneWidget);
    expect(find.text('未开始'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('评审中'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);

    // 任务卡片按状态入列（开发任务，非用户故事）：
    // devt-1 done / devt-2 review / devt-3 inProgress / devt-4 todo
    expect(find.text('实现产品登记表单'), findsOneWidget);
    expect(find.text('产品清单接口'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('kanban-column-review')),
        matching: find.text('产品清单接口'),
      ),
      findsOneWidget,
    );
    // 任务卡片标注来源故事（可追溯）
    expect(find.text('← 故事甲一'), findsNWidgets(2));

    // 拖拽：devt-1（已完成列）→ 未开始列（向左拖）
    await tester.timedDrag(
      find.text('实现产品登记表单'),
      const Offset(-700, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    // 拖入后：未开始列计数 1 → 2（devt-4 + 拖入 devt-1）
    expect(find.text('实现产品登记表单'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('kanban-column-todo')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('kanban-column-done')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('验收清单：按故事分组 + 状态切换 + 筛选', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('nav-acceptance')));
    await tester.pumpAndSettle();

    // 顶部统计：全部 3 / 通过 1 / 失败 1 / 未验收 1（通过率 33%）
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-total')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-passed')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-failed')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-pending')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.text('33%'), findsOneWidget);

    // 按故事分组：组头（故事标题 + 进度）
    expect(find.text('故事甲一'), findsOneWidget);
    expect(find.text('通过 1/1'), findsOneWidget);
    expect(find.text('通过 0/1'), findsNWidgets(2));

    // 验收项标题 + 来源徽标（需求验收 x2 / 异常场景 x1）+ 失败原因
    expect(find.text('登记后表单清空并提示成功'), findsOneWidget);
    expect(find.text('切换器空间互不干扰'), findsOneWidget);
    expect(find.text('评审不通过的故事退回重写'), findsOneWidget);
    expect(find.text('需求验收'), findsNWidgets(2));
    expect(find.text('异常场景'), findsOneWidget);
    expect(find.text('原因：驳回后地图未刷新'), findsOneWidget);

    // 点击未验收项（acc-2）→ 通过
    await tester.tap(find.byKey(const Key('acceptance-item-acc-2')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-passed')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-pending')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(find.text('通过 1/1'), findsNWidgets(2));

    // 点击已通过项（acc-1）→ 失败（默认原因：打回开发）
    await tester.tap(find.byKey(const Key('acceptance-item-acc-1')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-failed')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('原因：验收未通过，已退回开发'), findsOneWidget);

    // 筛选：失败 → 只显示失败项（acc-1 / acc-3），通过项被过滤
    await tester.tap(find.byKey(const Key('filter-failed')));
    await tester.pumpAndSettle();
    expect(find.text('登记后表单清空并提示成功'), findsOneWidget);
    expect(find.text('评审不通过的故事退回重写'), findsOneWidget);
    expect(find.text('切换器空间互不干扰'), findsNothing);

    // 恢复全部
    await tester.tap(find.byKey(const Key('filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('切换器空间互不干扰'), findsOneWidget);
  });

  testWidgets('运营：维护者反思 + 用户反馈双 Tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('nav-operations')));
    await tester.pumpAndSettle();

    // 双 Tab + 计数
    expect(find.byKey(const Key('ops-tab-thoughts')), findsOneWidget);
    expect(find.byKey(const Key('ops-tab-feedback')), findsOneWidget);
    expect(find.text('维护者反思'), findsOneWidget);
    expect(find.text('用户反馈'), findsOneWidget);

    // 默认 Tab：维护者反思（最新在前）+ 作者徽标 + 关联故事
    expect(find.text('看板改成开发任务后，验收入口的引导还不够。'), findsOneWidget);
    expect(find.text('规格页的事件风暴成了评审的主战场，讨论具体很多。'), findsOneWidget);
    expect(find.text('产品经理'), findsOneWidget);
    expect(find.text('研发'), findsOneWidget);
    expect(find.text('← 故事甲一'), findsOneWidget);
    expect(find.text('← 故事甲三'), findsOneWidget);
    // 反馈内容默认不可见
    expect(find.text('异常分支多了以后主线很长，希望能折叠。'), findsNothing);

    // 切到用户反馈
    await tester.tap(find.byKey(const Key('ops-tab-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('异常分支多了以后主线很长，希望能折叠。'), findsOneWidget);
    expect(find.text('触屏拖拽不灵敏，希望有按钮流转。'), findsOneWidget);
    // 类型徽标：建议 / 问题
    expect(find.text('建议'), findsOneWidget);
    expect(find.text('问题'), findsOneWidget);
    // 状态：未处理（fb-1） / 已转需求（fb-2）
    expect(find.text('未处理'), findsOneWidget);
    expect(find.text('已转需求'), findsOneWidget);

    // 点击状态循环：已转需求 → 未处理
    await tester.tap(find.byKey(const Key('feedback-status-fb-2')));
    await tester.pumpAndSettle();
    expect(find.text('未处理'), findsNWidgets(2));

    // 再点：未处理 → 已采纳
    await tester.tap(find.byKey(const Key('feedback-status-fb-2')));
    await tester.pumpAndSettle();
    expect(find.text('已采纳'), findsOneWidget);
  });

  testWidgets('默认页面为量潮产品云（qtcloud-product）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Product simple(String id, String name, String title) => Product(
          id: id,
          name: name,
          title: title,
          tagline: '',
          designIdea: '',
          storyMap: StoryMap(id: 'm-$id', name: name),
        );

    await tester.pumpWidget(MaterialApp(
      home: ProductCloudScreen(products: [
        simple('a', 'qtcloud-devops', 'DevOps 测试'),
        simple('b', 'qtcloud-product', '产品云测试'),
      ]),
    ));
    await tester.pumpAndSettle();

    // 默认展示量潮产品云，而非第一个产品
    expect(find.text('产品云测试'), findsWidgets);
    expect(find.text('DevOps 测试'), findsNothing);
  });

  testWidgets('Release 行可折叠与展开', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    expect(find.text('故事甲一'), findsOneWidget);

    await tester.tap(find.byKey(const Key('release-toggle-MVP 版本')));
    await tester.pumpAndSettle();
    expect(find.text('故事甲一'), findsNothing);

    await tester.tap(find.byKey(const Key('release-toggle-MVP 版本')));
    await tester.pumpAndSettle();
    expect(find.text('故事甲一'), findsOneWidget);
  });
}

/// 旧格式活动（原始 Map，与种子数据同构）
Map<String, dynamic> _activity(String id, String title, List<Map<String, dynamic>> tasks) =>
    {'id': id, 'title': title, 'order': 0, 'tasks': tasks};

Map<String, dynamic> _task(
        String id, String title, String activityId, List<Map<String, dynamic>> stories) =>
    {'id': id, 'title': title, 'activityId': activityId, 'order': 0, 'stories': stories};

Map<String, dynamic> _story(
        String id, String title, String taskId, String phase, String status) =>
    {'id': id, 'title': title, 'taskId': taskId, 'phase': phase, 'status': status};

/// 夹具产品（不依赖种子数据）
List<Product> _fixtureProducts() {
  return [
    Product(
      id: 'alpha',
      name: 'alpha',
      title: '测试产品甲',
      tagline: '组件测试夹具：不依赖种子数据',
      designIdea: '夹具设计思路',
      devTasks: const [
        DevTask(
          id: 'devt-1',
          title: '实现产品登记表单',
          storyId: 'story-1-1',
          status: StoryStatus.done,
        ),
        DevTask(
          id: 'devt-2',
          title: '产品清单接口',
          storyId: 'story-1-1',
          status: StoryStatus.review,
        ),
        DevTask(
          id: 'devt-3',
          title: '空间切换器组件',
          storyId: 'story-1-2',
          status: StoryStatus.inProgress,
        ),
        DevTask(
          id: 'devt-4',
          title: '故事编辑表单',
          storyId: 'story-1-3',
          status: StoryStatus.todo,
        ),
      ],
      acceptances: const [
        AcceptanceItem(
          id: 'acc-1',
          title: '登记后表单清空并提示成功',
          storyId: 'story-1-1',
          status: AcceptanceStatus.passed,
        ),
        AcceptanceItem(
          id: 'acc-2',
          title: '切换器空间互不干扰',
          storyId: 'story-1-2',
          status: AcceptanceStatus.pending,
        ),
        AcceptanceItem(
          id: 'acc-3',
          title: '评审不通过的故事退回重写',
          storyId: 'story-1-3',
          source: AcceptanceSource.spec,
          eventId: 'evt-rejected',
          status: AcceptanceStatus.failed,
          note: '驳回后地图未刷新',
        ),
      ],
      maintainerThoughts: const [
        MaintainerThought(
          id: 'thought-1',
          content: '规格页的事件风暴成了评审的主战场，讨论具体很多。',
          author: '产品经理',
          createdAt: '5月18日',
          storyId: 'story-1-3',
        ),
        MaintainerThought(
          id: 'thought-2',
          content: '看板改成开发任务后，验收入口的引导还不够。',
          author: '研发',
          createdAt: '5月20日',
          storyId: 'story-1-1',
        ),
      ],
      userFeedback: const [
        UserFeedback(
          id: 'fb-1',
          content: '异常分支多了以后主线很长，希望能折叠。',
          type: FeedbackType.suggestion,
          createdAt: '5月19日',
          storyId: 'story-1-3',
        ),
        UserFeedback(
          id: 'fb-2',
          content: '触屏拖拽不灵敏，希望有按钮流转。',
          type: FeedbackType.issue,
          createdAt: '5月21日',
          status: FeedbackStatus.toRequirements,
          storyId: 'story-1-1',
        ),
      ],
      eventStorm: EventStorming(
        id: 'es-alpha',
        productId: 'alpha',
        title: '测试场景',
        description: '夹具事件风暴',
        nodes: [
          const StormNode(id: 'pm', type: StormNodeType.actor, title: '产品经理'),
          const StormNode(
            id: 'cmd-register',
            type: StormNodeType.command,
            title: '登记产品',
            actorId: 'pm',
          ),
          const StormNode(
            id: 'cmd-release',
            type: StormNodeType.command,
            title: '发布版本',
            actorId: 'pm',
          ),
          const StormNode(
            id: 'agg-catalog',
            type: StormNodeType.aggregate,
            title: '产品目录',
          ),
          const StormNode(
            id: 'evt-register',
            type: StormNodeType.event,
            title: '产品已登记',
            order: 0,
            commandId: 'cmd-register',
            aggregateId: 'agg-catalog',
            actorId: 'pm',
          ),
          const StormNode(
            id: 'evt-rejected',
            type: StormNodeType.event,
            title: '故事已被驳回',
            order: 1,
            commandId: 'cmd-register',
            aggregateId: 'agg-catalog',
            actorId: 'pm',
            isException: true,
            fromEventId: 'evt-register',
          ),
          const StormNode(
            id: 'evt-release',
            type: StormNodeType.event,
            title: '版本已发布',
            order: 2,
            commandId: 'cmd-release',
            aggregateId: 'agg-catalog',
            actorId: 'pm',
          ),
        ],
      ),
      storyMap: StoryMap(
        id: 'map-alpha',
        name: 'alpha',
        mvpLinePosition: 0.4,
        activities: [
          _activity('act-1', '活动甲', [
            _task('task-1-1', '任务甲一', 'act-1', [
              _story('story-1-1', '故事甲一', 'task-1-1', 'mvp', 'done'),
              _story('story-1-2', '故事甲二', 'task-1-1', 'future', 'todo'),
            ]),
            _task('task-1-2', '任务甲二', 'act-1', [
              _story('story-1-3', '故事甲三', 'task-1-2', 'mvp', 'review'),
            ]),
            // 扩展任务列数，保证矩阵水平溢出（滚动条拇指渲染的测试前提）
            _task('task-1-3', '任务甲三', 'act-1', [
              _story('story-1-4', '故事甲四', 'task-1-3', 'mvp', 'todo'),
            ]),
            _task('task-1-4', '任务甲四', 'act-1', [
              _story('story-1-5', '故事甲五', 'task-1-4', 'mvp', 'todo'),
            ]),
            _task('task-1-5', '任务甲五', 'act-1', [
              _story('story-1-6', '故事甲六', 'task-1-5', 'mvp', 'todo'),
            ]),
            _task('task-1-6', '任务甲六', 'act-1', [
              _story('story-1-7', '故事甲七', 'task-1-6', 'mvp', 'todo'),
            ]),
          ]),
          _activity('act-2', '活动乙', [
            _task('task-2-1', '任务乙一', 'act-2', [
              _story('story-2-1', '故事乙一', 'task-2-1', 'mvp', 'todo'),
            ]),
          ]),
        ],
      ),
    ),
    Product(
      id: 'beta',
      name: 'beta',
      title: '测试产品乙',
      tagline: '乙定位',
      designIdea: '',
      storyMap: StoryMap(id: 'map-beta', name: 'beta', activities: [
        _activity('act-3', '活动丙', [
          _task('task-3-1', '任务丙一', 'act-3', [
            _story('story-3-1', '故事丙一', 'task-3-1', 'mvp', 'done'),
          ]),
        ]),
      ]),
    ),
    Product(
      id: 'gamma',
      name: 'gamma',
      title: '测试产品丙',
      tagline: '丙定位',
      designIdea: '',
      storyMap: StoryMap(id: 'map-gamma', name: 'gamma', activities: [
        _activity('act-4', '活动丁', [
          _task('task-4-1', '任务丁一', 'act-4', [
            _story('story-4-1', '故事丁一', 'task-4-1', 'future', 'todo'),
          ]),
        ]),
      ]),
    ),
  ];
}
